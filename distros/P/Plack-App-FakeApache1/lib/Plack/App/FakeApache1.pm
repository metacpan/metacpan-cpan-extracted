package Plack::App::FakeApache1;
{
  $Plack::App::FakeApache1::DIST = 'Plack-App-FakeApache1';
}
$Plack::App::FakeApache1::VERSION = '0.0.5';
# ABSTRACT: Perl distro to aid in mod_perl1->PSGI migration
use strict;
use warnings;

use Plack::Util;
use Plack::Util::Accessor qw( handler dir_config );
use parent qw( Plack::Component );
use attributes;

use Plack::App::FakeApache1::Request;
use Plack::App::FakeApache1::Constants qw(OK);

use Carp;
use HTTP::Status qw(:constants);
use Scalar::Util qw( blessed );

sub call {
    my ($self, $env) = @_;

    my $fake_req = Plack::App::FakeApache1::Request->new(
        env         => $env,
        dir_config  => $self->dir_config,
    );
    $fake_req->status( HTTP_OK );

    my $handler;
    if ( blessed $self->handler ) {
        $handler = sub { $self->handler->handler( $fake_req ) };
    } else {
        my $class   = $self->handler;
        my $method = eval { $class->can("handler") };

        if ( grep { $_ eq 'method' } attributes::get($method) ) {
            $handler = sub { $class->$method( $fake_req ) };
        } else {
            $handler = $method;
        }
    }

    my $result = $handler->( $fake_req );

    if ( $result != OK ) {
        $fake_req->status( $result );
    }

    return $fake_req->finalize;
}

sub prepare_app {
    my $self    = shift;
    my $handler = $self->handler;

    carp "handler not defined" unless defined $handler;

    $handler = Plack::Util::load_class( $handler ) unless blessed $handler;
    $self->handler( $handler );

    return;
}

1;

=pod

=encoding UTF-8

=head1 NAME

Plack::App::FakeApache1 - Perl distro to aid in mod_perl1->PSGI migration

=head1 VERSION

version 0.0.5

=head1 AUTHOR

Chisel <chisel@chizography.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Chisel Wright.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__
# vim: ts=8 sts=4 et sw=4 sr sta
