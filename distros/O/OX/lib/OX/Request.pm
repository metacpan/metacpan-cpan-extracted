package OX::Request;
BEGIN {
  $OX::Request::AUTHORITY = 'cpan:STEVAN';
}
$OX::Request::VERSION = '0.14';
use Moose;
use namespace::autoclean;
# ABSTRACT: request object for OX

extends 'Web::Request' => { -version => 0.05 };


sub default_encoding { 'UTF-8' }
sub response_class   { 'OX::Response' }

sub _router { (shift)->env->{'ox.router'} }


sub mapping {
    my $self = shift;
    my $match = $self->env->{'plack.router.match'};
    return unless $match;
    return $match->mapping;
}


sub uri_for {
    my ($self, $route) = @_;

    my $uri_base = $self->script_name || '/';
    $uri_base .= '/' unless $uri_base =~ m+/$+;

    if (!ref($route)) {
        $route = { name => $route };
    }

    my $path_info = $self->_router->uri_for( %$route );

    confess "No URI found for route"
        unless defined($path_info);

    return $uri_base . $path_info;
}

__PACKAGE__->meta->make_immutable;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OX::Request - request object for OX

=head1 VERSION

version 0.14

=head1 SYNOPSIS

  use OX::Request;

  my $req = OX::Request->new(env => $env);

=head1 DESCRIPTION

This class is a simple subclass of L<Web::Request> which adds a couple more
features. It adds some methods to access various useful parts of the routing
process, and it also sets the C<default_encoding> to C<UTF-8>.

=head1 METHODS

=head2 mapping

This returns the C<mapping> of the current router match, if you are using
L<Path::Router> as the router.

=head2 uri_for($route)

This calls C<uri_for> on the given route hashref, and returns the absolute URI
path that results (including prepending C<SCRIPT_NAME>). If a string is passed
rather than a hashref, this is treated as equivalent to
C<< { name => $route } >>.

=for Pod::Coverage default_encoding
  response_class

=head1 AUTHORS

=over 4

=item *

Stevan Little <stevan.little@iinteractive.com>

=item *

Jesse Luehrs <doy@tozt.net>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
