package Spike::Log;

use strict;
use warnings;

use POSIX qw(strftime);
use Time::HiRes;

our $time_format = '%Y-%m-%d %H:%M:#S';

our $log_format  = '%2$s [%3$s] %1$s';
our $log_bind    = '][';

our $bind_values = undef;

sub format_time {
    my $time = shift // Time::HiRes::time();

    my $i_time = int $time;
    my $f_time = $time - $i_time;

    my @time = localtime $i_time;

    (my $format = $time_format) =~ s!#S!sprintf("%07.4f", $time[0] + $f_time)!e;

    return strftime($format, @time);
}

sub format_log { sprintf($log_format, $_[0], format_time, join($log_bind, @{$bind_values || [$$]})) }

$SIG{__WARN__} = sub { warn format_log($_[0]) };
$SIG{__DIE__}  = sub { die ref $_[0] ? $_[0] : format_log($_[0]) if $^S };

1;
