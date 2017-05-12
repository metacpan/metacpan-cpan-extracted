package Bread::Board::LifeCycle::Request;
BEGIN {
  $Bread::Board::LifeCycle::Request::AUTHORITY = 'cpan:STEVAN';
}
$Bread::Board::LifeCycle::Request::VERSION = '0.14';
use Moose::Role;
use namespace::autoclean;
# ABSTRACT: lifecycle for request-scoped services


# just behaves like a singleton - ::Request instances
# will get flushed after the response is sent
with 'Bread::Board::LifeCycle::Singleton';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bread::Board::LifeCycle::Request - lifecycle for request-scoped services

=head1 VERSION

version 0.14

=head1 SYNOPSIS

  service Controller => (
      class     => 'MyApp::Controller',
      lifecycle => 'Request',
  );

or, with L<Bread::Board::Declare>:

  has controller => (
      is        => 'ro',
      isa       => 'MyApp::Controller',
      lifecycle => 'Request',
  );

=head1 DESCRIPTION

This implements a request-scoped lifecycle for L<Bread::Board>. Services with
this lifecycle will persist throughout a single request as though they were a
L<Singleton|Bread::Board::Lifecycle::Singleton>, but they will be cleared when
the request is finished.

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
