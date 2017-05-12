package Parse::Syslog;

use Carp;
use Symbol;
use Time::Local;
use IO::File;
use strict;
use vars qw($VERSION);

$VERSION = '1.10';

my %months_map = (
    'Jan' => 0, 'Feb' => 1, 'Mar' => 2,
    'Apr' => 3, 'May' => 4, 'Jun' => 5,
    'Jul' => 6, 'Aug' => 7, 'Sep' => 8,
    'Oct' => 9, 'Nov' =>10, 'Dec' =>11,
    'jan' => 0, 'feb' => 1, 'mar' => 2,
    'apr' => 3, 'may' => 4, 'jun' => 5,
    'jul' => 6, 'aug' => 7, 'sep' => 8,
    'oct' => 9, 'nov' =>10, 'dec' =>11,
);

sub is_dst_switch($$$)
{
    my ($self, $t, $time) = @_;

    # calculate the time in one hour and see if the difference is 3600 seconds.
    # if not, we are in a dst-switch hour
    # note that right now we only support 1-hour dst offsets

    # cache the result
    if(defined $self->{is_dst_switch_last_hour} and
        $self->{is_dst_switch_last_hour} == $t->[3]<<5+$t->[2]) {
        return @{$self->{is_dst_switch_result}};
    }

    # calculate a number out of the day and hour to identify the hour
    $self->{is_dst_switch_last_hour} = $t->[3]<<5+$t->[2];

    # calculating hour+1 (below) is a problem if the hour is 23. as far as I
    # know, nobody does the DST switch at this time, so just assume it isn't
    # DST switch if the hour is 23.
    if($t->[2]==23) {
        @{$self->{is_dst_switch_result}} = (0, undef);
        return @{$self->{is_dst_switch_result}};
    }

    # let's see the timestamp in one hour
    # 0: sec, 1: min, 2: h, 3: day, 4: month, 5: year
    my $time_plus_1h = timelocal($t->[0], $t->[1], $t->[2]+1, $t->[3], $t->[4], $t->[5]);

    if($time_plus_1h - $time > 4000) {
        @{$self->{is_dst_switch_result}} = (3600, $time-$time%3600+3600);
    }
    else {
        @{$self->{is_dst_switch_result}} = (0, undef);
    }

    return @{$self->{is_dst_switch_result}};
}

# fast timelocal, cache minute's timestamp
# don't cache more than minute because of daylight saving time switch
# 0: sec, 1: min, 2: h, 3: day, 4: month, 5: year
sub str2time($$$$$$$$)
{
    my $self = shift @_;
    my $GMT = pop @_;

    my $lastmin = $self->{str2time_lastmin};
    if(defined $lastmin and
        $lastmin->[0] == $_[1] and
        $lastmin->[1] == $_[2] and
        $lastmin->[2] == $_[3] and
        $lastmin->[3] == $_[4] and
        $lastmin->[4] == $_[5])
    {
        $self->{last_time} = $self->{str2time_lastmin_time} + $_[0];
        return $self->{last_time} + ($self->{dst_comp}||0);
    }

    my $time;
    if($GMT) {
        $time = timegm(@_);
    }
    else {
        $time = timelocal(@_);
    }

    # compensate for DST-switch
    # - if a timewarp is detected (1:00 -> 1:30 -> 1:00):
    # - test if we are in a DST-switch-hour
    # - compensate if yes
    # note that we assume that the DST-switch goes like this:
    # time   1:00  1:30  2:00  2:30  2:00  2:30  3:00  3:30
    # stamp   1     2     3     4     3     3     7     8  
    # comp.   0     0     0     0     2     2     0     0
    # result  1     2     3     4     5     6     7     8
    # old Time::Local versions behave differently (1 2  5 6 5 6 7 8)

    if(!$GMT and !defined $self->{dst_comp} and
        defined $self->{last_time} and
        $self->{last_time}-$time > 1200 and
        $self->{last_time}-$time < 3600)
    {
        my ($off, $until) = $self->is_dst_switch(\@_, $time);
        if($off) {
            $self->{dst_comp} = $off;
            $self->{dst_comp_until} = $until;
        }
    }
    if(defined $self->{dst_comp_until} and $time > $self->{dst_comp_until}) {
        delete $self->{dst_comp};
        delete $self->{dst_comp_until};
    }

    $self->{str2time_lastmin} = [ @_[1..5] ];
    $self->{str2time_lastmin_time} = $time-$_[0];
    $self->{last_time} = $time;
    return $time+($self->{dst_comp}||0);
}

sub _use_locale($)
{
    use POSIX qw(locale_h strftime);
    my $old_locale = setlocale(LC_TIME);
    for my $locale (@_) {
        croak "new(): wrong 'locale' value: '$locale'" unless setlocale(LC_TIME, $locale);
        for my $month (0..11) {
            $months_map{strftime("%b", 0, 0, 0, 1, $month, 96)} = $month;
        }
    }
    setlocale(LC_TIME, $old_locale);
}


sub new($$;%)
{
    my ($class, $file, %data) = @_;
    croak "new() requires one argument: file" unless defined $file;
    %data = () unless %data;
    if(not defined $data{year}) {
        $data{year} = (localtime(time))[5]+1900;
    }
    $data{type} = 'syslog' unless defined $data{type};
    $data{_repeat}=0;

    if(UNIVERSAL::isa($file, 'IO::Handle')) {
        $data{file} = $file;
    }
    elsif(UNIVERSAL::isa($file, 'File::Tail')) {
        $data{file} = $file;
        $data{filetail}=1;
    }
    elsif(! ref $file) {
        if($file eq '-') {
            my $io = new IO::Handle;
            $data{file} = $io->fdopen(fileno(STDIN),"r");
        }
        else {
            $data{file} = new IO::File($file, "<");
            defined $data{file} or croak "can't open $file: $!";
        }
    }
    else {
        croak "argument must be either a file-name or an IO::Handle object.";
    }

    if(defined $data{locale}) {
        if(ref $data{locale} eq 'ARRAY') {
            _use_locale @{$data{locale}};
        }
        elsif(ref $data{locale} eq '') {
            _use_locale $data{locale};
        }
        else {
            croak "'locale' parameter must be scalar or array of scalars";
        }
    }

    return bless \%data, $class;
}

sub _year_increment($$)
{
    my ($self, $mon) = @_;

    # year change
    if($mon==0) {
        $self->{year}++ if defined $self->{_last_mon} and $self->{_last_mon} == 11;
        $self->{enable_year_decrement} = 1;
    }
    elsif($mon == 11) {
        if($self->{enable_year_decrement}) {
            $self->{year}-- if defined $self->{_last_mon} and $self->{_last_mon} != 11;
        }
    }
    else {
        $self->{enable_year_decrement} = 0;
    }

    $self->{_last_mon} = $mon;
}

sub _next_line($)
{
    my $self = shift;
    my $f = $self->{file};
    if(defined $self->{filetail}) {
        return $f->read;
    }
    else {
        return $f->getline;
    }
}

sub _next_syslog($)
{
    my ($self) = @_;

    while($self->{_repeat}>0) {
        $self->{_repeat}--;
        return $self->{_repeat_data};
    }

    my $file = $self->{file};
    line: while(defined (my $str = $self->_next_line)) {
        # date, time and host 
        $str =~ /^
            (\S{3})\s+(\d+)      # date  -- 1, 2
            \s
            (\d+):(\d+):(\d+)    # time  -- 3, 4, 5
            (?:\s<\w+\.\w+>)?    # FreeBSD's verbose-mode
            \s
            ([-\w\.\@:]+)        # host  -- 6
            \s+
            (?:\[LOG_[A-Z]+\]\s+)?  # FreeBSD
            (.*)                 # text  -- 7
            $/x or do
        {
            warn "WARNING: line not in syslog format: $str";
            next line;
        };
        
        my $mon = $months_map{$1};
        defined $mon or croak "unknown month $1\n";

        $self->_year_increment($mon);

        # convert to unix time
        my $time = $self->str2time($5,$4,$3,$2,$mon,$self->{year}-1900,$self->{GMT});
        if(not $self->{allow_future}) {
            # accept maximum one day in the present future
            if($time - time > 86400) {
                warn "WARNING: ignoring future date in syslog line: $str";
                next line;
            }
        }

        my ($host, $text) = ($6, $7);

        # last message repeated ... times
        if($text =~ /^(?:last message repeated|above message repeats) (\d+) time/) {
            next line if defined $self->{repeat} and not $self->{repeat};
            next line if not defined $self->{_last_data}{$host};
            $1 > 0 or do {
                warn "WARNING: last message repeated 0 or less times??\n";
                next line;
            };
            $self->{_repeat}=$1-1;
            $self->{_repeat_data}=$self->{_last_data}{$host};
            return $self->{_last_data}{$host};
        }

        # marks
        next if $text eq '-- MARK --';

        # some systems send over the network their
        # hostname prefixed to the text. strip that.
        $text =~ s/^$host\s+//;

        # discard ':' in HP-UX 'su' entries like this:
        # Apr 24 19:09:40 remedy : su : + tty?? root-oracle
        $text =~ s/^:\s+//;

        $text =~ /^
            ([^:]+?)        # program   -- 1
            (?:\[(\d+)\])?  # PID       -- 2
            :\s+
            (?:\[ID\ (\d+)\ ([a-z0-9]+)\.([a-z]+)\]\ )?   # Solaris 8 "message id" -- 3, 4, 5
            (.*)            # text      -- 6
            $/x or do
        {
            warn "WARNING: line not in syslog format: $str";
            next line;
        };

        if($self->{arrayref}) {
            $self->{_last_data}{$host} = [
                $time,  # 0: timestamp 
                $host,  # 1: host      
                $1,     # 2: program   
                $2,     # 3: pid       
                $6,     # 4: text      
                ];
        }
        else {
            $self->{_last_data}{$host} = {
                timestamp => $time,
                host      => $host,
                program   => $1,
                pid       => $2,
                msgid     => $3,
                facility  => $4,
                level     => $5,
                text      => $6,
            };
        }

        return $self->{_last_data}{$host};
    }
    return undef;
}

sub _next_metalog($)
{
    my ($self) = @_;
    my $file = $self->{file};
    line: while(my $str = $self->_next_line) {
	# date, time and host 
	
	$str =~ /^
            (\S{3})\s+(\d+)   # date  -- 1, 2
            \s
            (\d+):(\d+):(\d+) # time  -- 3, 4, 5
	                      # host is not logged
            \s+
            (.*)              # text  -- 6
            $/x or do
        {
            warn "WARNING: line not in metalog format: $str";
            next line;
        };
	
        my $mon = $months_map{$1};
        defined $mon or croak "unknown month $1\n";

        $self->_year_increment($mon);

        # convert to unix time
        my $time = $self->str2time($5,$4,$3,$2,$mon,$self->{year}-1900,$self->{GMT});
	
	my $text = $6;

        $text =~ /^
            \[(.*?)\]        # program   -- 1
           	             # no PID
	    \s+
            (.*)             # text      -- 2
            $/x or do
        {
	    warn "WARNING: text line not in metalog format: $text ($str)";
            next line;
        };

        if($self->{arrayref}) {
            return [
                $time,  # 0: timestamp 
                'localhost',  # 1: host      
                $1,     # 2: program   
                undef,  # 3: (no) pid
                $2,     # 4: text
                ];
        }
        else {
            return {
                timestamp => $time,
                host      => 'localhost',
                program   => $1,
                text      => $2,
            };
        }
    }
    return undef;
}

sub next($)
{
    my ($self) = @_;
    if($self->{type} eq 'syslog') {
        return $self->_next_syslog();
    }
    elsif($self->{type} eq 'metalog') {
        return $self->_next_metalog();
    }
    croak "Internal error: unknown type: $self->{type}";
}

1;

__END__

=head1 NAME

Parse::Syslog - Parse Unix syslog files

=head1 SYNOPSIS

 my $parser = Parse::Syslog->new( '/var/log/syslog', year => 2001);
 while(my $sl = $parser->next) {
     ... access $sl->{timestamp|host|program|pid|text} ...
 }

=head1 DESCRIPTION

Unix syslogs are convenient to read for humans but because of small differences
between operating systems and things like 'last message repeated xx times' not
very easy to parse by a script.

Parse::Syslog presents a simple interface to parse syslog files: you create
a parser on a file (with B<new>) and call B<next> to get one line at a time
with Unix-timestamp, host, program, pid and text returned in a hash-reference.

=head2 Constructing a Parser

B<new> requires as first argument a source from where to get the syslog lines. It can
be:

=over 4

=item *

a file-name for the syslog-file to be parsed.

=item *

an IO::Handle object.

=item *

a File::Tail object as first argument, in which
case the I<read> method will be called to get lines to process.

=back

After the file-name (or File::Tail object), you can specify options as a hash.
The following options are defined:

=over 8

=item B<type>

Format of the "syslog" file. Can be one of:

=over 8

=item I<syslog>

Traditional "syslog" (default)

=item I<metalog>

Metalog (see http://metalog.sourceforge.net/)

=back

=item B<year>

Syslog files usually do store the time of the event without year. With this
option you can specify the start-year of this log. If not specified, it will be
set to the current year.

=item B<GMT>

If this option is set, the time in the syslog will be converted assuming it is
GMT time instead of local time.

=item B<repeat>

Parse::Syslog will by default repeat xx times events that are followed by
messages like 'last message repeated xx times'. If you set this option to
false, it won't do that.

=item B<arrayref>

If this option is true, I<next> will return an array-ref instead of a hash-ref
(and is thus a bit faster), with the following contents:

=over 4

=item 0:

timestamp

=item 1:

host

=item 2:

program

=item 3:

pid

=item 4:

text

=back

=item B<locale>

Optional. Specifies an additional locale name or the array of locale names for
the parsing of log files with national characters.

=item B<allow_future>

If true will allow for timestamps in the future. Otherwise timestamps of one day
in the future and more will not be returned (as a safety measure against wrong
configurations, bogus --year arguments, etc.)

=back

=head2 Parsing the file

The file is parse one line at a time by calling the B<next> method, which returns
a hash-reference containing the following keys:

=over 10

=item B<timestamp>

Unix timestamp for the event.

=item B<host>

Host-name where the event did happen.

=item B<program>

Program-name of the program that generated the event.

=item B<pid>

PID of the Program that generated the event. This information
is not always available for every operating system.

=item B<text>

Text description of the event.

=item B<msgid>

Message numeric identifier, available only on Solaris >= 8 with "message ID
generation" enabled".

=item B<facility>

Log facility name, available only on Solaris >= 8 with "message ID
generation" enabled".

=item B<level>

Log level, available only on Solaris >= 8 with "message ID
generation" enabled".

=back

=head2 BUGS

There are many small differences in the syslog syntax between operating
systems. This module has been tested for syslog files produced by the following
operating systems:

    Debian GNU/Linux 2.4 (sid)
    Solaris 2.6
    Solaris 8

Report problems for these and other operating systems to the author.

=head1 COPYRIGHT

Copyright (c) 2001, Swiss Federal Institute of Technology, Zurich.
All Rights Reserved.

=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

David Schweikert <dws@ee.ethz.ch>

=head1 HISTORY

 2001-08-12 ds 0.01 first version
 2001-08-19 ds 0.02 fix 'last message repeated xx times', Solaris 8 problems
 2001-08-20 ds 0.03 implemented GMT option, year specification, File::Tail
 2001-10-31 ds 0.04 faster time parsing, implemented 'arrayref' option, better time-increment algorithm
 2002-01-29 ds 0.05 ignore -- MARK -- lines, low-case months, space in program names
 2002-05-02 ds 1.00 HP-UX fixes, parse 'above message repeats xx times'
 2002-05-25 ds 1.01 added support for localized month names (uchum@mail.ru)
 2002-10-28 ds 1.02 fix off-by-one-hour error when running during daylight saving time switch
 2004-01-19 ds 1.03 do not allow future dates (if allow_future is not true)
 2004-07-11 ds 1.04 added support for type 'metalog'
 2005-12-24 ds 1.05 allow passing of a IO::Handle object to new

=cut

# vi: sw=4 et
