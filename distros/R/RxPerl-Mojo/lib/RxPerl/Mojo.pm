package RxPerl::Mojo;
use 5.010;
use strict;
use warnings;

use parent 'RxPerl::Base';

use RxPerl ':all';

use Mojo::IOLoop;
use Sub::Util 'set_subname';

use Exporter 'import';
our @EXPORT_OK = @RxPerl::EXPORT_OK;
our %EXPORT_TAGS = %RxPerl::EXPORT_TAGS;

our $VERSION = "v6.8.1";

our $promise_class = 'Mojo::Promise';

foreach my $func_name (@EXPORT_OK) {
    set_subname __PACKAGE__."::$func_name", \&{$func_name};
}

sub _timer {
    my ($after, $sub) = @_;

    my $id;
    $id = Mojo::IOLoop->timer($after, sub {
        undef $id;
        $sub->();
    });

    return \$id;
}

sub _cancel_timer {
    my ($id_ref) = @_;

    defined $id_ref and defined $$id_ref or return;

    Mojo::IOLoop->remove($$id_ref);
}

sub _interval {
    my ($after, $sub) = @_;

    my $id = Mojo::IOLoop->recurring($after, $sub);

    return $id;
}

sub _cancel_interval {
    my ($id) = @_;

    defined $id or return;

    Mojo::IOLoop->remove($id);
}



1;
__END__

=encoding utf-8

=head1 NAME

RxPerl::Mojo - Mojo::IOLoop adapter for RxPerl

=head1 SYNOPSIS

    use RxPerl::Mojo ':all';
    use Mojo::IOLoop;

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

    Mojo::IOLoop->start;

=head1 DESCRIPTION

RxPerl::Mojo is a module that lets you use the L<RxPerl> Reactive Extensions in your Mojolicious app
or app that uses Mojo::IOLoop.

=head1 DOCUMENTATION

The documentation at L<RxPerl> applies to this module too.

=head1 NOTIFICATIONS FOR NEW RELEASES

You can start receiving emails for new releases of this, or other, modules, over at L<https://perlmodules.net>.

=head1 COMMUNITY CODE OF CONDUCT

The Community Code of Conduct can be found L<here|RxPerl::Mojo::CodeOfConduct>.

=head1 LICENSE

Copyright (C) 2020 Karelcom OÜ.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Alexander Karelas E<lt>karjala@cpan.orgE<gt>

=cut
