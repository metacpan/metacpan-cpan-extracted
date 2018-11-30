package Perl::Critic::Policy::Freenode::Threads;

use strict;
use warnings;

use Perl::Critic::Utils qw(:severities :classification :ppi);
use parent 'Perl::Critic::Policy';

our $VERSION = '0.028';

use constant DESC => 'Using interpreter threads';
use constant EXPL => 'Interpreter threads are discouraged, they are not lightweight and fast as other threads may be. Try an event loop, forks.pm, or Parallel::Prefork.';

sub supported_parameters { () }
sub default_severity { $SEVERITY_MEDIUM }
sub default_themes { 'freenode' }
sub applies_to { 'PPI::Statement::Include' }

sub violates {
	my ($self, $elem) = @_;
	return $self->violation(DESC, EXPL, $elem) if $elem->pragma eq 'threads';
	return ();
}

1;

=head1 NAME

Perl::Critic::Policy::Freenode::Threads - Interpreter-based threads are
officially discouraged

=head1 DESCRIPTION

Perl interpreter L<threads> are officially discouraged. They were created to
emulate C<fork()> in Windows environments, and are not fast or lightweight as
one may expect. Non-blocking code or I/O can be easily parallelized by using an
event loop such as L<POE>, L<IO::Async>, or L<Mojo::IOLoop>. Blocking code is
usually better parallelized by forking, which on Unix-like systems is fast and
efficient. Modules such as L<forks> and L<Parallel::Prefork> can make forking
easier to work with, as well as forking modules for event loops such as
L<POE::Wheel::Run>, L<IO::Async::Process>, or L<Mojo::IOLoop/"subprocess">.

=head1 AFFILIATION

This policy is part of L<Perl::Critic::Freenode>.

=head1 CONFIGURATION

This policy is not configurable except for the standard options.

=head1 AUTHOR

Dan Book, C<dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2015, Dan Book.

This library is free software; you may redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<Perl::Critic>
