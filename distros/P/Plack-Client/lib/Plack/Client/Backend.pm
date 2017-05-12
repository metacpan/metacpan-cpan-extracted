package Plack::Client::Backend;
BEGIN {
  $Plack::Client::Backend::VERSION = '0.06';
}
use strict;
use warnings;
# ABSTRACT: turns a Plack::Request into a PSGI app

use Carp;
use Scalar::Util qw(weaken);

use overload '&{}' => sub { shift->as_code(@_) }, fallback => 1;



sub new {
    my $class = shift;
    bless {}, $class;
}


sub app_from_request {
    croak "Backends must implement app_from_request";
}


sub as_code {
    my $self = shift;
    return sub { $self->app_from_request(@_) };
}

1;

__END__
=pod

=head1 NAME

Plack::Client::Backend - turns a Plack::Request into a PSGI app

=head1 VERSION

version 0.06

=head1 SYNOPSIS

  package My::Backend;
  use base 'Plack::Client::Backend';

  sub app_from_request {
      my $self = shift;
      my ($req) = @_;
      return sub { ... }
  }

=head1 DESCRIPTION

This is a base class for L<Plack::Client> backends. These backends are handlers
for a particular URL scheme, and translate a L<Plack::Request> instance into a
PSGI application coderef.

=head1 METHODS

=head2 new

Creates a new backend instance. Takes no parameters by default, but may be
overridden in subclasses.

=head2 app_from_request

This method is called with an argument of a L<Plack::Request> object, and
should return a PSGI application coderef. The Plack::Request object it receives
contains the actual env hash that will be passed to the application, so
backends can modify that too, if they need to.

=head2 as_code

Returns a coderef which will call L</app_from_request> as a method.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Plack::Client|Plack::Client>

=back

=head1 AUTHOR

Jesse Luehrs <doy at tozt dot net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jesse Luehrs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

