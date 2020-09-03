package RxPerl::IOAsync;
use strict;
use warnings FATAL => 'all';

use RxPerl ':all';

use IO::Async::Timer::Countdown;
use IO::Async::Timer::Periodic;
use Sub::Util 'set_subname';

use Exporter 'import';
our @EXPORT_OK = @RxPerl::EXPORT_OK;
our %EXPORT_TAGS = %RxPerl::EXPORT_TAGS;

foreach my $func_name (@EXPORT_OK) {
    set_subname __PACKAGE__."::$func_name", \&{$func_name};
}

our $loop;
sub set_loop { $loop = $_[0] }

sub _timer {
    my ($after, $sub) = @_;

    my $timer = IO::Async::Timer::Countdown->new(
        delay            => $after,
        on_expire        => $sub,
        remove_on_expire => 1,
    );

    $timer->start;
    $loop->add($timer);

    return $timer;
}

sub _cancel_timer {
    my ($timer) = @_;

    defined $timer or return;

    $timer->remove_from_parent;
}

sub _interval {
    my ($after, $sub) = @_;

    my $timer = IO::Async::Timer::Periodic->new(
        interval   => $after,
        on_tick    => $sub,
        reschedule => 'hard',
    );

    $timer->start;
    $loop->add($timer);

    return $timer;
}

sub _cancel_interval {
    my ($timer) = @_;

    defined $timer or return;

    $timer->remove_from_parent;
}

1;
