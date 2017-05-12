package Plack::Middleware::Timed::Logger;

use 5.16.0;
use strict;
use warnings;

use parent qw(Plack::Middleware);
use Timed::Logger;

=head1 NAME

Plack::Middleware::Timed::Logger - Expose a Timed::Logger Instance in Middleware

=head1 VERSION

Version 0.0.5

=cut

our $VERSION = '0.0.5';

=head1 SYNOPSIS

    use Plack::Builder;
    builder {
      enable 'Timed::Logger';
      $app;
    };

=head1 DESCRIPTION

L<Plack::Middleware::Timed::Logger> does one thing, it places an instance of
L<Timed::Logger> into the C<$env> under C<plack.middleware.timed.logger>.
A new instance is created for each incoming request.

This middleware is intended to act as a bridge between L<Timed::Logger>, which
holds log of the events, with a reporting tool such as seen in
L<Plack::Middleware::Debug::Timed::Logger>.

Unless you are building some custom logging tools, you probably just want to
use the existing debug panel (L<Plack::Middleware::Debug::Timed::Logger>)
rather than building something custom around this middleware.

If you are using Dancer to build your web application you may want to use
L<Timed::Logger::Dancer::AdoptPlack> to help you to bridge Dancer's conrollers
with this middleware.

This module was inspired by L<Plack::Middleware::DBIC::QueryLog>.

=head1 SUBROUTINES

This middleware defines the following public subroutines

=head2 PSGI_KEY

Returns the PSGI C<$env> key under which you'd expect to find an instance of
L<Timed::Logger>.

=head2 get_logger_from_env

Given a L<Plack> C<$env>, returns a L<Timed::Logger>.
You should use this in your code that is trying to access the logger. For
example:

    use Plack::Middleware::Timed::Logger;

    sub logger {
      my ($self, $env) = @_;
      Plack::Middleware::Timed::Logger->get_logger_from_env($env);
    }

This function creates a new instance of L<Timed::Logger> if one doesn't exist already.
This is the officially supported interface for extracting a L<Timed::Logger> from a L<Plack> request.

=head2 call

An callback used by Plack to call this middleware.

=cut

sub PSGI_KEY {'plack.middleware.timed.logger'}

sub get_logger_from_env {
  my ($self, $env) = @_;
  #Create a new logger if one is not defined already
  $env->{+PSGI_KEY} ||= Timed::Logger->new();
  return $env->{+PSGI_KEY};
}

sub call {
  my ($self, $env) = @_;
  $env->{+PSGI_KEY} ||= Timed::Logger->new();
  $self->app->($env);
}

=head1 SEE ALSO

L<Timed::Logger>, L<Plack::Middleware::Debug::Timed::Logger>,
L<Timed::Logger::Dancer::AdoptPlack>

=head1 AUTHOR

Nikolay Martynov, C<< <kolya at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-plack-middleware-timed-logger at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Plack-Middleware-Timed-Logger>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Plack::Middleware::Timed::Logger


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Plack-Middleware-Timed-Logger>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Plack-Middleware-Timed-Logger>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Plack-Middleware-Timed-Logger>

=item * Search CPAN

L<http://search.cpan.org/dist/Plack-Middleware-Timed-Logger/>

=back


=head1 ACKNOWLEDGEMENTS

Logan Bell and Belden Lyman.

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Nikolay Martynov and Shutterstock Inc (http://shutterstock.com). All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1; # End of Plack::Middleware::Timed::Logger
