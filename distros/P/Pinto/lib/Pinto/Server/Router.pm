# ABSTRACT: Routes server requests

package Pinto::Server::Router;

use Moose;

use Scalar::Util;
use Plack::Request;
use Router::Simple;

#-------------------------------------------------------------------------------

our $VERSION = '0.097'; # VERSION

#-------------------------------------------------------------------------------

has route_handler => (
    is      => 'ro',
    isa     => 'Router::Simple',
    default => sub { Router::Simple->new },
);

#-------------------------------------------------------------------------------

sub BUILD {
    my ($self) = @_;

    my $r = $self->route_handler;

    $r->connect( '/action/{action}', { responder => 'Action' }, { method => 'POST' } );

    $r->connect( '/*', { responder => 'File' }, { method => [ 'GET', 'HEAD' ] } );

    return $self;
}

#-------------------------------------------------------------------------------


sub route {
    my ( $self, $env, $root ) = @_;

    my $p = $self->route_handler->match($env)
        or return [ 404, [], ['Not Found'] ];

    my $responder_class = 'Pinto::Server::Responder::' . $p->{responder};
    Class::Load::load_class($responder_class);

    my $request = Plack::Request->new($env);
    my $responder = $responder_class->new( request => $request, root => $root );

    # HACK: Plack-1.02 calls URI::Escape::uri_escape() with arguments
    # that inadvertently cause $_ to be compiled into a regex.  This
    # will emit warning if $_ is undef, or may blow up if it contains
    # certain stuff.  To avoid this, just make sure $_ is empty for
    # now.  A patch has been sent to Miyagawa.
    local $_ = '';

    return $responder->respond;
}

#-------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#-------------------------------------------------------------------------------

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Jeffrey Ryan Thalhammer BenRifkah Fowler Jakob Voss Karen Etheridge Michael
G. Bergsten-Buret Schwern Oleg Gashev Steffen Schwigon Tommy Stanton
Wolfgang Kinkeldei Yanick Boris Champoux hesco popl Däppen Cory G Watson
David Steinbrunner Glenn responder

=head1 NAME

Pinto::Server::Router - Routes server requests

=head1 VERSION

version 0.097

=head1 METHODS

=head2 route( $env, $root )

Given the request environment and the path to the repository root,
dispatches the request to the appropriate responder and returns the
response.

=for Pod::Coverage BUILD

=head1 AUTHOR

Jeffrey Ryan Thalhammer <jeff@stratopan.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jeffrey Ryan Thalhammer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
