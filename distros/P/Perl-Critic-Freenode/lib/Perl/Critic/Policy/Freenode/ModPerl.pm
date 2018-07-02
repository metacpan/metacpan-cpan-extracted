package Perl::Critic::Policy::Freenode::ModPerl;

use strict;
use warnings;

use Perl::Critic::Utils qw(:severities :classification :ppi);
use parent 'Perl::Critic::Policy';

our $VERSION = '0.027';

use constant DESC => 'Using mod_perl';
use constant EXPL => 'mod_perl is not designed for writing Perl web applications. Try a Plack-based framework (Web::Simple, Dancer2, Catalyst) or Mojolicious for a modern approach.';

sub supported_parameters { () }
sub default_severity { $SEVERITY_HIGH }
sub default_themes { 'freenode' }
sub applies_to { 'PPI::Statement::Include' }

my %modules = (
	'Apache'            => 1,
	'Apache::Constants' => 1,
	'Apache::Registry'  => 1,
	'Apache::Request'   => 1,
	'Apache2::Const'    => 1,
	'Apache2::Request'  => 1,
	'ModPerl::Const'    => 1,
	'ModPerl::Registry' => 1,
);

sub violates {
	my ($self, $elem) = @_;
	return $self->violation(DESC, EXPL, $elem) if exists $modules{$elem->module//''};
	return ();
}

1;

=head1 NAME

Perl::Critic::Policy::Freenode::ModPerl - Don't use mod_perl to write web
applications

=head1 DESCRIPTION

L<mod_perl|http://perl.apache.org/> is an embedded Perl interpreter for the
L<Apache|http://www.apache.org/> web server. It allows you to dynamically
configure and mod Apache. It is not a generally good solution for writing web
applications. Frameworks using L<Plack> (L<Web::Simple>, L<Dancer2>,
L<Catalyst>) and L<Mojolicious> are much more flexible, powerful, and stable.
A web application written in one of these frameworks can be deployed using a
Perl HTTP server such as L<Starman> or L<Mojo::Server::Hypnotoad>; by proxy
from Apache or nginx; or even run as if they were regular CGI scripts.

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
