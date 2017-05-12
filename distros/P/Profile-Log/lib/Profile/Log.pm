
=head1 NAME

Profile::Log - collect loggable application profiling stats

=head1 SYNOPSIS

 use Profile::Log;

 ...

 sub event_processor {
     my $timer = Profile::Log->new() if PROFILE;

     do_something();
     $timer->did("minor") if PROFILE > 1;

     $timer->mark("parallel") if PROFILE;
     do_parallel_things();

     wait_for_thing1();
     $timer->did("thing1", "parallel") if PROFILE;

     wait_for_thing2();
     $timer->did("thing2", "parallel") if PROFILE;

     finish_up();
     $timer->did("finish") if PROFILE > 1;

     # this module does not handle logging itself.
     print LOG $timer->logline if PROFILE;
 }

 # later... available processing methods
 my $timer = Profile::Log->new($log_line);
 print $timer->zero;  # profile start time
 print $timer->end;   # profile stop time

 # ... t.b.c. ...

=head1 DESCRIPTION

C<Profile::Log> is about breaking down time spent in "critical paths",
such as in transaction processing servers, into logical pieces - with
easily tunable operation that does not incur undue performance
penalities when it is not being used.

C<Profile::Log> exports the C<PROFILE> constant into the environment,
depending on how it is configured (see L</CONFIGURATION>).  This will
be set if profiling has been selected for the given script or module.
As this is exported as a "constant subroutine", using the module as
per the above synopsis will not incur any penalty at all (except, in
the case above, the allocation of one undef scalar and the
compile-time inclusion of C<Profile::Log> itself; in long-running
application servers, this is an extremely minor concern).

The timing information is logged in a way that suits syslog, and is
casually easy to inspect; the above example, on profiling level 2,
might log (though all on one line):

 0=12:34:56.123504; tot=0.504; minor: 0.020; m0:parallel=0.000; \
    m0:thing1=0.450; m0:thing2=0.454; finish: 0.030

The first item is the time that the C<Profile::Log> object was
created.  The "tot" is the total length of time from when the object
was created to the time that it was stopped (such as by asking for the
log line).

On profiling level 1, you would instead get (assuming the same times
for each component):

 0=12:34:56.123504; tot=0.504; m0:parallel=0.020; \
    m0:thing1=0.450; m0:thing2=0.454

=cut

package Profile::Log;

use strict;
use warnings;

use Carp;

use Time::HiRes qw(gettimeofday tv_interval);
use YAML qw(LoadFile Dump);
use List::Util qw(reduce);
use Scalar::Util qw(blessed);

our $VERSION = "0.02";

=head1 EXPORTS

This module exports the C<PROFILE> constant to the caller's namespace.
This will be set to 0 by default, or a number if configured in the
per-user or environment specified configuration file.  See
L</CONFIGURATION> for details.

If PROFILE is already defined as a subroutine or C<use constant> in
the calling package, then that is not touched.

=cut

our $config;

sub import {
    my $package = shift;
    my ($caller_package, $filename) = caller;
    if ( defined &{$caller_package."::PROFILE"} ) {
	print STDERR (__PACKAGE__.": bypassing auto-config for "
		      ."$filename ($caller_package) - PROFILE already"
		      ." defined\n")
	    if $ENV{PROFILE_LOG_DEBUG};
    } else {
	$filename =~ s{.*/}{};
	$config ||= do {
	    my $config_file = ($ENV{PROFILE_LOG_CONFIG} ||
			       "$ENV{HOME}/.profilerc.yml");
	    if ( -e $config_file ) {
		print STDERR __PACKAGE__.": loading settings from $config_file\n"
		    if $ENV{PROFILE_LOG_DEBUG};
		LoadFile $config_file
	    } else {
		{};
	    }
	};

	#print STDERR "Config is: ".Dump($config);
	#print STDERR "stuff is: ".Dump({caller_package => $caller_package,
	#filename => $filename });

	my %import_config;
	if ( $config->{modules} and $config->{modules}{$caller_package} ) {
	    %import_config = %{ $config->{modules}{$caller_package} };
	}
	if ( $config->{files} and $config->{files}{$filename} ) {
	    %import_config = (%import_config,
			      %{ $config->{files}{$filename} });
	}

	my $profiling = $import_config{profile} || 0;
	print STDERR (__PACKAGE__.": profiling level for $filename "
		      ."($caller_package) is $profiling\n")
	    if $ENV{PROFILE_LOG_DEBUG};

	no strict 'refs';
	*{$caller_package."::PROFILE"} = sub() {
	    $profiling;
	};
    }
}


=head1 CONSTRUCTOR

 my $timer = Profile::Log->new() if PROFILE;

Mark beginning of a profiled section, by creating a new
C<Profile::Log> object.

Normally, you don't pass any arguments to the C<Profile::Log-E<gt>new>
constructor.  However, if you want to reconstruct a previous
C<Profile::Log> object from a line from your logs, then you can pass
that in instead.

 my $loaded_timer = Profile::Log->new($log_line);

For now, you need to strip off any leading C<syslog> wrappers to the
front of the string you pass in as C<$log_line>.

=cut

sub new {
    my $class = shift;
    if ( @_ ) {
	my $logline = shift;
 	my ($state);
	my $self = bless { t => [], mc => 0 }, $class;
	my $time;
	my @marks;
	while ( $logline =~ m{\G([^=]+)=([^;]*)(?:;\s+)?}g ) {
	    my ($k, $v) = ($1, $2);
	    if ( !$state and $k ne "0" ) {
		$self->{tag}{$k}=$v;
	    }
	    elsif ( !$state and $k eq "0" ) {
		$v =~ m{(\d+):(\d+):(\d+)\.(\d+)};
		$self->{0} = to_local([ (reduce { $a * 60 + $b } $1, $2, $3),
					$4 * 10**(6-length($4)) ]);
		$time = $self->{0};
		$state = "tot";
	    } elsif ( $state eq "tot" ) {
		$self->{Z} = time_add($time,[0,$v*1e6]);
		$state = "times"
	    } elsif ( $state eq "times" ) {
		push @{ $self->{t} }, $k, $v;
		if ( $k =~ m{m(\d+):(.*)} ) {
		    my ($m, $label) = ($1, $2);
		    if ( $m >= $self->{mc} ) {
			$marks[$m] = $label;
			$time = $self->{m}{$label}
			    = time_add($time, [0,$v*1e6]);
			$self->{mc}++;
		    } else {
			$time = time_add($self->{m}{$marks[$m]},
					 [0,$v*1e6]);
		    }
		} else {
		    $time = time_add($time,[0,$v*1e6]);
		}
	    }
	}
	return $self;
    }
    else {
    my @now = gettimeofday;
    return bless { 0 => \@now,
		   l => [@now],
		   m => {},
		   mc => 0,
		   t => [],
		 }, $class;
    }
}

=head2 ALTERNATE CONSTRUCTOR

It is also possible to feed in lines that came out of L<syslog(8)>.
These are expected to be in the form:

  Mon DD HH:MM:SS hostname ...

These must be fed into the alternate constructor
C<-E<gt>new_from_syslog>.  Information present in the syslog line,
such as the hostname, any process name (sans PID), and extra
information leading up to the beginning of the C<-E<gt>logline()> part
are put into tags.

=cut

sub new_from_syslog {
    my $class = shift;
    my $line = shift;

    my ($syslog_line, $logline)
	= ($line =~ m{^(.*?)(\S[^=\s]*=[^;]*;\s.*)$})
	    or return undef;
    my $self = $class->new($logline);
    $self->add_syslog($syslog_line);
    return $self;
}

# this is a bit of a hack - a version of timelocal for syslog dates
my $timelocal_ready;
our %mon;
our ($y,$m,$d);
sub syslog_timelocal {
    my $syslog_date = shift;
    my ($sec, $min, $hour, $mday, $monname) = reverse
	( $syslog_date =~ m{^(\w+) \s+ (\d+) \s+ (\d+):(\d+):(\d+)}x );

    unless ( $timelocal_ready ) {
	no strict 'refs';
	require I18N::Langinfo;
	require Time::Local;
	for my $mon ( 1..12 ) {
	    my $mname = lc(&I18N::Langinfo::langinfo
			   (&{"I18N::Langinfo::ABMON_$mon"}));
	    $mon{$mname} = $mon-1;
	}
	($y, $m, $d) = (localtime(time()))[5,4,3];
	$timelocal_ready = 1;
    }
    # if the month is greater than today, assume it's last year.
    my $mon = $mon{lc($monname)};
    #kill 2, $$;
    my $year = ($mon > $m) ? $y-1 : $y;
    return Time::Local::timelocal($sec, $min, $hour,
				  $mday, $mon, $year);
}

sub add_syslog {
    my $self = shift;
    my $syslog_header = shift;

    if ( my ($syslog_date, $hostname, $process, $comment)
	 = ( $syslog_header =~
	     m{^(\w+ \s+ \d+ \s+ \d+:\d+:\d+) \s+ # syslog date
	       (\w+) \s+                         # hostname
	       (?: (\S+?) (?:\[\d+\])? : \s* )?  # process name, PID
	       (?: (\S.*?) \s* )? $                   # extra comment
	   }x )) {

	$self->tag("hostname" => $hostname);
	$self->tag("process" => $process);
	$self->tag("comment" => $comment) if $comment;

	if ( $self->{0}[0] < 7 * 86400 ) {
	    # we set the top half of the 0 to the month and day *not later
	    # than* the syslog time.
	    my $syslog_localtime = syslog_timelocal($syslog_date);
	    my $self_time = $self->{0}[0] % 86400;

	    my @local_syslog = localtime($syslog_localtime);
	    my @local_self   = localtime($self_time);

	    my $proposed_time = Time::Local::timelocal
		(@local_self[0,1,2],@local_syslog[3,4,5]);

	    if ( $proposed_time > $syslog_localtime ) {
		# must be the previous day
		$syslog_localtime -= 86400;
		@local_syslog = localtime($syslog_localtime);
		$proposed_time = Time::Local::timelocal
		    (@local_self[0,1,2],@local_syslog[3,4,5]);
	    }

	    my $old_time = $self->{0}[0];
	    my ($old_diff) = ($self->{Z}[0] - $self->{0}[0]) % 86400;
	    $self->{0}[0] = $proposed_time;
	    $self->{Z}[0] = $proposed_time + $old_diff;
	    if ( $self->{m} ) {
		my $to_add = ($proposed_time - $old_time);
		while ( my ($mark, $t) = each %{$self->{m}} ) {
		    $t->[0] += $to_add;
		}
	    }
	}
    }
}

my $tz_offset;
sub to_local {
    my $t = shift;
    # FIXME - non-hour aligned timezones like NZ-CHAT
    $t->[0] -= ($tz_offset ||= ((localtime(0))[2])) * 3600;
    $t->[0] %= 86400 if $t->[0] < 0;
    $t;
}

sub time_add {
    my $t1 = shift;
    my $t2 = shift;
    my $usec = $t1->[1] + $t2->[1];
    return [ $t1->[0] + $t2->[0] + int($usec / 1e6),
	     $usec % 1e6 ];
}

=head1 OBJECT METHODS

=head2 TIMING METHODS

=over

=item C<-E<gt>did($event, [$mark])>

Indicate that the time elapsed since the timer was constructed or the
last time C<-E<gt>did()> or C<-E<gt>mark()> was called to the current
time was spent doing "C<$event>".  If you specify a C<$mark> (see
below), then all the time back from when you created that mark is
considered to have been spent doing C<$event>.

=cut

sub did {
    my $self = shift;
    my $event = shift;
    $event !~ m{\s} or croak "event must not contain whitespace";
    my $t0;
    if ( @_ ) {
	my $mark = shift;
	$t0 = $self->{m}{$mark};
	$event = "m$t0->[2]:$event";
    } else {
	$t0 = $self->{l};
    }
    my $now = [gettimeofday];
    push @{ $self->{t} }, ($event => tv_interval($t0, $now));
    $self->{l} = $now;
}

=item C<-E<gt>mark($mark)>

Set a time mark for later back-reference.  Typically you would call
this just before doing something that involves running things in
parallel, and call C<-E<gt>did()> above with the optional C<$mark>
parameter when each independent task completes.

=cut

sub mark {
    my $self = shift;
    my $mark = shift;
    $mark !~ m{\s} or croak "mark must not contain whitespace";
    # this is a touch naughty - hang extra information on the nice
    # handy array there (Time::HiRes doesn't care)
    my $m;
    $self->{m}{$mark}=[gettimeofday, ($m=$self->{mc}++)];
    $self->did("m$m:$mark");
}

=item C<-E<gt>logline()>

Returns the timing information in a summarised format, suitable for
sending to C<syslog> or something similar.

This method automatically stops the timer the first time it is called.

=back

=cut

sub logline {
    my $self = shift;
    my $final = ($self->{Z}||=[gettimeofday]);

    my @ts;

    @ts = map { "$_=$self->{tag}{$_}" } sort keys %{ $self->{tag} }
	if $self->{tag};

    push @ts, ("0=".$self->getTimeStamp($self->{0}),
	       "tot=".$self->getInterval($self->{0}, $final));
    my $l = $self->{t};

    # collect rounding errors along the way, fudge onto the next value
    # so they don't accumulate.  ie, if one task takes 0.4074s, and
    # the next 0.0011s, they will be displayed as 0.407 and 0.002
    my $re = 0;
    for ( my $i = 0; $i < $#$l; $i += 2 ) {
	my $delta = $l->[$i+1] + $re;
	my $ms;
	# very short deltas might end up negative - so add the error
	# to the next value instead.
	if ( $delta < 0 ) {
	    ($ms, my $extra) = getInterval($l->[$i+1]);
	    $re += $extra;
	} else {
	    ($ms, $re) = getInterval($delta);
	}
	push @ts, "$l->[$i]=$ms";
    }
    return join ("; ", @ts);
}

=head2 TRACKING AND INSPECTING METHODS

These methods are about making sure custom details about what is being
logged can easily be logged with the profiling information.

For instance, in application servers it is often useful to log the
type of transaction being processed, or the URL.  In multi-tier
systems, you need to log a unique identifier with each request if you
are to correlate individual timings through the system.

Also, these methods cover getting useful information out of the object
once you have read it in from a log file.

=over

=item C<-E<gt>tag($tag, [$value])>

Set (2 argument version) or get (1 argument version) an arbitrary tag.
The C<$tag> name should not contain a semicolon or equals sign, and
the C<$value> must not contain any semicolons.  This is not enforced.

=item C<-E<gt>tags>

Returns a list of tags of this profile, in no particular order.

=cut

sub tag {
    my $self = shift;
    my $title = shift;
    $title !~ m{[\s=;]}
	or croak("tag name must not contain whitespace, equals symbol"
		 ." or semicolon");
    if ( @_ ) {
	my $value = shift;
	$self->{tag}{$title}=$value;
    }
    else {
	return $self->{tag}{$title};
    }
}

sub tags {
    my $self = shift;

    return keys %{ $self->{tag} };
}

=item C<-E<gt>zero>

Return the number of seconds between midnight (UTC) and the time this
profiling object was created.

In list context, returns a Unix epoch time and a number of
microseconds, C<Time::HiRes> style.

=cut

sub zero {
    my $self = shift;
    return $self->{0}[0] % 86400 + $self->{0}[1] / 1e6;
}

sub zero_t {
    my $self = shift;
    return @{ $self->{0} }
}

=item C<-E<gt>diff($t2)>

Returns the difference between two times, in seconds.  If the dates
are fully specified, then it will return an asolute (floating point)
number of seconds.

This method is available as the overloaded C<cmp> operator, for easy
use with C<sort>.

=cut

sub diff {
    my $a = shift;
    my $b = shift;

    my @a = $a->zero;
    my @b = $b->zero;

    # Profile::Log objects don't need fully qualified dates; if the
    # date value is too small, then compare by seconds only, in the
    # closest half of the day.
    if ( $a[0] > 10*86400 and $b[0] > 10*86400 ) {
	return $a[0] - $b[0] + ( $a[0] - $b[0] ) / 1e6;
    } else {
	my $diff = ( ($a[0] - $b[0]) % 86400
		     + ( $a[0] - $b[0] ) / 1e6);
	$diff += 86400 if $diff < -86400/2;
	$diff -= 86400 if $diff >  86400/2;
	return $diff;
    }
}

use overload
    'cmp' => \&diff,
    'fallback' => 1;

=item C<-E<gt>end>

Return the number of seconds since midnight (UTC) and the time this
profiling object's clock was stopped.

=cut

sub end {
    my $self = shift;
    my $z = $self->{Z}||=[gettimeofday];
    return $z->[0] % 86400 + $z->[1] / 1e6;
}

sub end_t {
    my $self = shift;
    my $z = $self->{Z}||=[gettimeofday];
    return @$z;
}

=item C<-E<gt>marks>

Returns a list of marks as an array.  This will always include "0",
the starting mark.

=cut

sub marks {
    my $self = shift;
    my @marks = (0, sort { tv_interval($self->{m}{$a}, $self->{m}{$b})
		       } keys %{ $self->{m}||{} });
    wantarray ? @marks : \@marks;
}

=item C<-E<gt>iter>

Returns an iterator that iterates over every delta, and mark, in the
Profiler object.

The iterator responds to these methods; note that these are not method
calls:

=over

=item C<$iter-E<gt>("next")>

iterate.  returns a true value unless there is nowhere to iterate to.

=item C<$iter-E<gt>("start")>

Returns the offset from time 0 that this delta started in fractional
seconds.

=item C<$iter-E<gt>("length")>

Returns the length of this delta in (fractional) seconds.

=item C<$iter-E<gt>("name")>

Returns the name of this delta, including the mark identifier (C<m>
followed by a number and a colon, such as "C<m0:>").

=back

=cut

sub iter {
    my $self = shift;

    my $i = -1;

    my $cue = 0;
    my @m = ();

    my $it = sub {
	$cue += $self->{t}[2*$i+1]
	    unless $i == -1 or $i*2+1 > ($#{$self->{t}});
	$i++;
	if ( $i*2 <= ($#{$self->{t}})
	     and $self->{t}[2*$i] =~ m/^m(\d+)/ ) {
	    if ( exists $m[$1] ) {
		$cue = $m[$1];
	    } else {
		$m[$1] = $cue;
	    }
	}
    };

    my $iter = sub {
	my $method = shift;
	if ( $method eq "next" ) {
	    $it->();
	    if ( 2*$i < $#{$self->{t}} ) {
		return $self->{t}[2*$i];
	    }
	    elsif ( 2*$i == $#{$self->{t}}+1 ) {
		return "Z";
	    }
	    else {
	    }
	}
	elsif ( $method eq "start" ) {
	    return $cue;
	}
	elsif ( $method eq "length" ) {
	    return 0 if $i == -1;
	    return scalar getInterval(($self->end - $self->zero) - $cue)
		if 2*$i == $#{$self->{t}}+1;
	    return $self->{t}[2*$i+1]+0;
	}
	elsif ( $method eq "name" ) {
	    return 0 if $i == -1;
	    return "Z" if 2*$i == $#{$self->{t}}+1;
	    return $self->{t}[2*$i];
	}
    };
    return $iter;
}

=item C<-E<gt>mark_iter([$mark])>

Returns an iterator that iterates exactly once over every delta that
was timed relative to C<$mark>.

If you don't pass a mark in, it iterates only over items that weren't
timed relative to C<$mark>.

=cut

sub mark_iter {
    my $self = shift;
    my $mark = shift || 0;
    my ($t0, $m);
    if ( $mark ne "0" ) {
	($m) = (map { m/^m(\d+):/; $1 }
		grep /^m\d+:\Q$mark\E/,
		@{ $self->{t} });
	croak("no such mark '$mark' in Profile::Log object (marks: "
	      .join(" ",keys %{ $self->{m}||{} }).")")
	    unless defined $m;
    }

    my $all_iter = $self->iter();

    my $iter = sub {
	my $method = shift;
	if ( $method eq "next" ) {
	    my $x;
	    do { $x = $all_iter->("next") } until
		(!$x or
		 !defined($m) && $all_iter->("name") !~ m/^m\d+:/
		 or
		 defined($m) && $all_iter->("name") =~ m/^m(\d+):/);
	    return $x;
	}
	elsif ( $method eq "name" ) {
	    my $name = $all_iter->("name");
	    $name =~ s{m\d+:}{};
	    return $name;
	}
	else {
	    return $all_iter->($method);
	}
    };

    $iter->("next") if defined($m);

    return $iter;
}


=back

=head2 TIMESTAMP FORMATTING

If you don't like the decisions I've made about only displaying
milliseconds in the log, then you may sub-class C<Profile::Log> and
provide these functions instead.  These are called as object methods,
though the object itself is not used to compute the result.

=over

=item C<-E<gt>getTimeStamp([$sec, $usec])>

Formats an absolute timestamp from a C<Time::HiRes> array.  Defaults
to formatting as: C<HH:MM:SS.SSS>

=cut

sub getTimeStamp {
    shift if blessed $_[0];
    my $when = shift || [ gettimeofday ];
    my ($endSeconds, $endMicroseconds) = @$when;
    my ($sec, $min, $hour) = localtime($endSeconds);

    return sprintf "%.2d:%.2d:%.2d.%.3d", $hour,$min,$sec,
	($endMicroseconds/1e3);
}

=item C<-E<gt>getInterval($sec | @tv_interval )>

Formats an interval.  This function accepts either a floating point
number of seconds, or arguments as accepted by
C<Time::HiRes::tv_interval>.

The function returns a string in scalar context, but in list context
returns any rounding error also, in floating point seconds.

=back

=cut

sub getInterval {
    shift if blessed $_[0];
    my $elapsed;
    if ( @_ == 2 or ref $_[0] ) {
	$elapsed = tv_interval(@_);
    } else {
	$elapsed = shift;
    }
    # only return milliseconds.
    my $fmt = sprintf("%.3f", $elapsed);
    return ( wantarray ? ($fmt, ($elapsed - $fmt)) : $fmt );
}

=head1 AUTHOR AND LICENSE

Designed and built by Sam Vilain, L<samv@cpan.org>, brought to you
courtesy of Catalyst IT Ltd - L<http://www.catalyst.net.nz/>.

All code and documentation copyright © 2005, Catalyst IT Ltd.  All
Rights Reserved.  This module is free software; you may use it and/or
redistribute it under the same terms as Perl itself.

=cut

1;
