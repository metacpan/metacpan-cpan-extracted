package RxPerl::IOAsync;
use 5.010;
use strict;
use warnings;

use RxPerl ':all';

use IO::Async::Timer::Countdown;
use IO::Async::Timer::Periodic;
use Sub::Util 'set_subname';

use Exporter 'import';
our @EXPORT_OK = @RxPerl::EXPORT_OK;
our %EXPORT_TAGS = %RxPerl::EXPORT_TAGS;

our $VERSION = "v6.0.0";

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
__END__

=encoding utf-8

=head1 NAME

RxPerl::IOAsync - IO::Async adapter for RxPerl

=head1 SYNOPSIS

    use RxPerl::IOAsync ':all';
    use IO::Async::Loop;

    my $loop = IO::Async::Loop->new;
    RxPerl::IOAsync::set_loop($loop);

    sub make_observer ($i) {
        return {
            next     => sub {say "next #$i: ", $_[0]},
            error    => sub {say "error #$i: ", $_[0]},
            complete => sub {say "complete #$i"},
        };
    }

    my $o = rx_interval(0.7)->pipe(
        op_map(sub {$_[0] * 2}),
        op_take_until( rx_timer(5) ),
    );

    $o->subscribe(make_observer(1));

    $loop->run;

=head1 DESCRIPTION

RxPerl::IOAsync is a module that lets you use the L<RxPerl> Reactive Extensions in your app that uses IO::Async.

=head1 DOCUMENTATION

The documentation at L<RxPerl> applies to this module too.

=head1 LICENSE

Copyright (C) Karelcom OÜ.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

KARJALA E<lt>karjala@cpan.orgE<gt>

=cut
