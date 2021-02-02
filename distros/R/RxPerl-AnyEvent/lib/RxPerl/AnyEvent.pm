package RxPerl::AnyEvent;
use 5.010;
use strict;
use warnings;

use RxPerl ':all';
use RxPerl::Utils 'immortalize', 'decapitate';

use AnyEvent;
use Sub::Util 'set_subname';

use Exporter 'import';
our @EXPORT_OK = @RxPerl::EXPORT_OK;
our %EXPORT_TAGS = %RxPerl::EXPORT_TAGS;

our $VERSION = "v6.0.1";

foreach my $func_name (@EXPORT_OK) {
    set_subname __PACKAGE__."::$func_name", \&{$func_name};
}

sub _timer {
    my ($after, $sub) = @_;

    my $w; $w = AnyEvent->timer(
        after => $after,
        cb    => $sub,
    );

    immortalize($w);

    return $w;
}

sub _cancel_timer {
    my ($w) = @_;

    defined $w or return;

    decapitate($w);
}

sub _interval {
    my ($after, $sub) = @_;

    my $w; $w = AnyEvent->timer(
        after    => $after,
        interval => $after,
        cb       => $sub,
    );

    immortalize($w);

    return $w;
}

sub _cancel_interval {
    my ($w) = @_;

    defined $w or return;

    decapitate($w);
}

1;
__END__

=encoding utf-8

=head1 NAME

RxPerl::AnyEvent - AnyEvent adapter for RxPerl

=head1 SYNOPSIS

    use RxPerl::AnyEvent ':all';
    use AnyEvent;

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

    AnyEvent->condvar->recv;

=head1 DESCRIPTION

RxPerl::AnyEvent is a module that lets you use the L<RxPerl> Reactive Extensions in your AnyEvent app.

=head1 DOCUMENTATION

The documentation at L<RxPerl> applies to this module too.

=head1 NOTIFICATIONS FOR NEW RELEASES

You can start receiving emails for new releases of this, or other, modules, over at L<https://perlmodules.net>.

=head1 LICENSE

Copyright (C) Karelcom OÜ.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Alexander Karelas E<lt>karjala@cpan.orgE<gt>

=cut
