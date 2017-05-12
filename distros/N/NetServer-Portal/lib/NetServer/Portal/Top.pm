use strict;
package NetServer::Portal::Top;
use NetServer::Portal qw(term $Host);
use Event qw(all_watchers QUEUES time);
use Event::Stats 0.7 qw(round_seconds idle_time total_time);

NetServer::Portal->register(cmd => "top",
			    title => "Process Top",
			    package => __PACKAGE__);

use vars qw($NextID %ID2W %W2ID %OldW2ID);

# keep state in a ref that can be saved with Storable...

sub new {
    my ($class, $client) = @_;
    my $o = $client->conf(__PACKAGE__);
    $o->{seconds} ||= round_seconds(60);
    $o->{filter} ||= '';
    $o->{by} ||= 't';
    $o->{page} ||= 1;
    $NextID ||= 1;
    $o;
}

sub enter {
    my ($o, $c) = @_;
    Event::Stats::collect(1);
    $c->{io}->timeout(4);
}

sub leave {
    # there's probably a better way to do this...? XXX
    Event->timer(desc => 'NetServer::Portal::Top->leave',
		 after => 15 * 60, cb => sub {
		     my $e = shift;
		     $e->w->cancel;
		     if (!Event::Stats::collect(-1)) {
			 %ID2W = ();
		     }
		 });
}

sub reset_idmap {
    %OldW2ID = %W2ID;
    if ($NextID > 2*keys %OldW2ID) {
	%OldW2ID=();  # too much fragmentation, start over
    }
    $NextID = 1;
    %W2ID=();
}
sub assign_id {  # assign unique ids without reassignments
    my ($w) = @_;
    my $id;
    if (exists $OldW2ID{ 0+$w } and !exists $ID2W{ $OldW2ID{ 0+$w } }) {
	$id = $OldW2ID{ 0+$w };
	$NextID = $id + 1
	    if $NextID < $id + 1;
    } else {
	$id = $NextID++;
    }
    $W2ID{ 0+$w } = $id;
    $ID2W{ $id } = $w;
    $id;
}

sub update {
    my ($o, $c) = @_;

    reset_idmap();

    my $uconf = $c->conf;
    my $s = term->Tgoto('cm', 0, 0, $c->{io}->fd);
    # my $s = term->Tputs('cl',1,$c->{io}->fd);
    my $ln = $c->format_line;
    my $name = $0;
    $name =~ s,^.*/,,;
    $s .= $ln->("$name PID=$$ \@ $Host");

    my ($sec,$min,$hr) = localtime(time);
    my $tm = sprintf("| %02d:%02d:%02d [%4ds]", $hr,$min,$sec,$o->{seconds});
    $s .= term->Tgoto('cm', $uconf->{cols} - (1+length $tm), 0, $c->{io}->fd);
    $s .= $tm."\n";

    my @load;
    my @events = all_watchers();
    for my $sec (15,60,60*15) {
	my $busy = 0;
	for (@events) { $busy += ($_->stats($sec))[2] }
	my $idle = (idle_time($sec))[2];
	my $tm = $idle + $busy;
	push @load, $tm? $busy / $tm : 0;
    }

    my @all = map {
	[{ obj  => $_,
	   id   => assign_id($_),
	   desc => $_->desc,
	   prio => $_->prio },
	 $_->stats($o->{seconds})] } @events;
    push @all, [{ id => 0, desc => 'idle', prio => QUEUES },
		idle_time($o->{seconds})];
    my $total = 0;
    for (@all) { $total += $_->[3] }
    my $other_tm = total_time($o->{seconds}) - $total;
    $other_tm = 0 if $other_tm < 0;
    push @all, [{ id => 0, desc => 'other processes', prio => -1 },
		0, 0, $other_tm];

    # $lag should not be affected by other processes
    my $lag = $total - $o->{seconds};
    $lag = 0 if $lag < 0;

    $s .= $ln->("%d events; load averages: %.2f, %.2f, %.2f; lag %2d%%",
		scalar @events, @load, $total? 100*$lag/$total : 0);
    $s .= "\n";

    $total += $other_tm; # add in other processes for %time [XXX optional?]

    my $filter = $o->{filter};
    @all = grep { $_->[0]{desc} =~ /$filter/ } @all
	if length $filter;

    $o->{page} = 1 if $o->{page} < 1;
    my $rows_per_page = $uconf->{rows} - 8;
    my $maxpage = int((@all + $rows_per_page - 1)/$rows_per_page);
    $o->{page} = $maxpage if $o->{page} > $maxpage;

    my $page = " P$o->{page}";
    $s .= $ln->("  EID PRI STATE   RAN  TIME   CPU TYPE DESCRIPTION");
    my $start_row = 4;
    $s .= term->Tgoto('cm', $uconf->{cols} - (1+length $page), $start_row-1,
		       $c->{io}->fd);
    $s .= $page."\n";

    if ($o->{by} eq 't') {
	@all = sort { $b->[3] <=> $a->[3] } @all;
    } elsif ($o->{by} eq 'i') {
	@all = sort { $a->[0]{id} <=> $b->[0]{id} } @all;
    } elsif ($o->{by} eq 'r') {
	@all = sort { $b->[1] <=> $a->[1] } @all;
    } elsif ($o->{by} eq 'd') {
	@all = sort { $a->[0]{desc} cmp $b->[0]{desc} } @all;
    } elsif ($o->{by} eq 'p') {
	@all = sort { $a->[0]{prio} cmp $b->[0]{prio} } @all;
    } else {
	warn "unknown sort by '$o->{by}'";
    }
    splice @all, 0, $rows_per_page * ($o->{page} - 1)
	if $o->{page} > 1;

    for (my $r = 0; $r < $rows_per_page; $r++) {
	my $st = shift @all;
	if ($st) {
	    my $e = $st->[0]{obj};
	    my ($type, $fstr);
	    if (!$e) {
		$type = 'sys';
		$fstr = '';
	    } else {
		$type = ref $e;
		$type =~ s/^Event:://;
		$fstr = do {
		    # make look pretty!
		    if ($e->is_suspended) {
			'S'.(($e->is_active? 'W':'').
			     ($e->is_running?'R':''))
		    } elsif ($e->is_running) {
			'cpu'
		    } elsif ($e->pending) {
			'queue'
		    } elsif ($e->is_active) {
			$type eq 'idle'? 'wait' : 'sleep'
		    } else {
			$type eq 'idle'? 'sleep' : 'zomb'
		    }
		};
	    }
	    my @prf = ($st->[0]{id},
		       $st->[0]{prio},
		       $fstr,
		       $st->[1],
		       int($st->[3]/60), $st->[3] % 60,
		       $total? 100 * $st->[3]/$total : 0,
		       substr($type,0,length($type)>4? 4:length($type)),
		       $st->[0]{desc});
#	    warn join('x', @prf)."\n";
	    my $line = sprintf("%5d  %2d %-5s %5d %2d:%02d%5.1f%% %4s %s", @prf);
	    $s .= $ln->($line);
	} else {
	    $s .= $ln->();
	}
    }

    $s .= "\n".$ln->($o->{error})."% ";
    $s;
}

sub cmd {
    my ($o, $c, $in) = @_;

    if ($in eq '') {
	$o->{error} = '';
    } elsif ($in eq 'h' or $in eq '?') {
	$c->set_screen('NetServer::Portal::Top::Help');
    } elsif ($in =~ m/^d\s*(\d+)$/) {
	$Event::DebugLevel = int $1;
    } elsif ($in =~ m/^o\s*(\w+)$/) {
	my $by = $1;
	if ($by =~ m/^(t|i|r|d|p)$/) {
	    $o->{by} = $by;
	} else {
	    $o->{error} = "Sort by '$by'?  Type 'h' for help!";
	}
    } elsif ($in =~ m/^p\s*(\d+)$/) {
	$o->{page} = $1 || 1;
    } elsif ($in =~ m/^(\,+)$/) {  # compatible with Pi key bindings
	$o->{page} -= length $1;
    } elsif ($in =~ m/^(\.+)$/) {
	$o->{page} += length $1;
    } elsif ($in =~ m/^e\s*(\d+)$/) {
	my $got = $ID2W{$1};
	if ($got) {
	    # XXX
	    $c->set_screen('NetServer::Portal::Top::Edit')->{edit} = $got;
	} else {
	    $o->{error} = "Can't find event id '$1'";
	}
    } elsif ($in =~ m{ ^/ (.*) $ }x) {
	$o->{filter} = $1;
    } elsif ($in =~ m/^t\s*(\d+)$/) {
	my $s = $1;
	my $max = &Event::Stats::MAXTIME;
	if ($s < 0) {
	    $o->{error} = "Sorry, past performance is not an indication of future performance.";
	} else {
	    $o->{seconds} = round_seconds($1);
	}
    } elsif ($in =~ m/^(s|r)\s*(\d+)$/) {
	my $do = $1;
	my $id = $2;
	my $ev = $ID2W{ $2 };
	if (!$ev) {
	    $o->{error} = "Can't find event '$id'.";
	} else {
	    $ev->suspend($do eq 's')
	}
    } else {
	$o->{error} = "'$in'?  Type 'h' for help!";
    }
}

package NetServer::Portal::Top::Edit;
use NetServer::Portal qw(term);

sub new { bless { error=>'' }, shift }

sub update {
    my ($o, $c) = @_;
    my $ln = $c->format_line;
    my $s = term->Tputs('cl',1,$c->{io}->fd);
    $s .= "Event Minieditor"."\n"x3;
    my $e = $o->{edit};
    if (!$e) {
	delete $o->{edit};
	$c->set_screen('NetServer::Portal::Top');
	return;
    }
    my $f = 'a';
    for my $k ($e->attributes) {
	my $v = $e->$k();
	$v = defined $v? $v:'<undef>';
	if (length $v > 40) {
	    $v = substr($v,0,40) . ' ...';
	}
	$v =~ s/\0/^0/g;
	$v =~ s/\n/\\n/g;
	$s .= $ln->("%s %-16s %-s", $f++, $k, $v);
    }
    $s .= $ln->();
    $s .= $ln->("(Use Zvalue to assign value to field 'Z'.  'x' when you are done.)");
    $s .= $ln->();
    $s .= $ln->($o->{error});
    $s .= "% ";
    $s;
}

sub cmd {
    my ($o, $c, $in) = @_;
    if ($in eq '') {
	# ignore
    } elsif ($in eq 'x') {
	delete $o->{edit};
	$c->set_screen('NetServer::Portal::Top');
    } elsif ($in =~ m/^(\w)\s*(.+)$/) {
	my $f = ord(lc $1) - ord 'a';
	my $v = $2;
	my $ev = $o->{edit};
	my @k = $ev->attributes;
	if ($f < 0 || $f >= @k) {
	    $o->{error} = "Field '$f' is not available";
	} else {
	    eval {
		my $m = $k[$f];
		$ev->$m($v)
	    }; #hope safe enough!
	    $o->{error} = $@ if $@;
	}
    } else {
	$o->{error} = "'$in'?";
    }
}

package NetServer::Portal::Top::Help;
use NetServer::Portal qw(term);

sub new { bless { }, shift }

sub update {
    my (undef, $c) = @_;
    my $o = $c->conf('NetServer::Portal::Top');
    my $s = term->Tputs('cl',1,$c->{io}->fd);
    $s .= "NetServer::Portal Help


  CMD      DESCRIPTION                                  
  -------- -----------------------------------------------------------
  d #      set Event::DebugLevel                         [$Event::DebugLevel]
  e #id    edit event
  h        this screen
  o #how   order by t=time, i=id, r=ran, d=desc, p=prio  [$o->{by}]
  p #page  switch to page #page                          [$o->{page}]
  r #id    resume event
  s #id    suspend event
  t #sec   show stats for the last #sec seconds          [$o->{seconds}]
  /regexp  show events with matching descriptions        [$o->{filter}]






(Press return to continue.)";
    $s;
}

sub cmd {
    my ($o, $c, $in) = @_;
    $c->set_screen('back');
}

1;

__END__

=head1 NAME

NetServer::Portal::Top - Make event loop statistics easily available

=head1 SYNOPSIS

  require NetServer::Portal::Top;

=head1 DESCRIPTION

All statistics collected by L<Event> are displayed in a format similar
to the popular (and excellent) C<top> program.

=head1 PRECISE STAT DEFINITIONS

=over 4

=item * idle

Idle tracks the amount of time that the process cooperatively
reliquished control to the operating system.  (Usually via L<select>
or L<poll>.)

=item * other processes

Attempts to estimate the process's non-idle time that the operating
system instead gave to other processes. (Actual clock time minus the
combined total time spent in idle and in running event handlers.)
This stat is an underestimate (lower bound) since the process can also
be preemptively interrupted I<during> event processing.

=item * lag

Lag is the percent over the I<planned amount of time> that the event
loop took to complete.  ((Actual time - planned time) / planned time)

=back

It is unfortunately that more intuitive stats are not available.
Benchmarking is a slippery business.  If you have ideas for
improvements, don't be shy!

=head1 SCREENSHOT

 pl/3bork  [12836 @ eq1062]                                    12:15:18 [  15s]
 21 events (6 zombies); load averages: 0.33, 0.32, 0.32                        
                                                                               
  EID PRI STATE  RAN  TIME  CPU  TYPE DESCRIPTION                            P1
    0   8 sleep  247  0:09 66.7%  sys idle                                     
   24   4 sleep  105  0:04 28.1% idle QSGTable sweep                           
    3   4 sleep   15  0:00  2.4% time server status                            
   22   4 sleep   15  0:00  1.8% time QSGTable                                 
   12   4 cpu      4  0:00  0.8% time NetServer::Portal::Client localhost      
   23   4 sleep   15  0:00  0.1% time QSGTable Detail                          
    2   4 sleep   15  0:00  0.0% time Qt                                       
    7   4 sleep    8  0:00  0.0% time ObjStore::Serve checkpoint               
   10   4 sleep    8  0:00  0.0% time SSL items                                
    9   4 sleep    8  0:00  0.0% time SSL service                              
    6  -1 sleep    5  0:00  0.0% time Event::Stats                             
   21   4 zomb     0  0:00  0.0% idle QSGTable sweep                           
   19   4 zomb     0  0:00  0.0% time QSGTable                                 
   11   4 sleep    0  0:00  0.0%   io NetServer::Portal::Client localhost      
    8   4 sleep    0  0:00  0.0%   io SSL                                      
   13   4 zomb     0  0:00  0.0% time QSGTable                                 

The three load averages are for the most recent 15 seconds, 1 minute,
and 15 minutes, respectively.

For efficiency, not all time intervals are available.  When you change
the time interval, it will be rounded to the closest for which there
is data.

=head1 BUGS

The potential impact of multiple CPUs and kernel-level thread support
is ignored.

=cut
