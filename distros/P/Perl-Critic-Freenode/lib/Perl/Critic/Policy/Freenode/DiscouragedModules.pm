package Perl::Critic::Policy::Freenode::DiscouragedModules;

use strict;
use warnings;

use Perl::Critic::Utils qw(:severities :classification :ppi);
use Perl::Critic::Violation;
use parent 'Perl::Critic::Policy';

our $VERSION = '0.024';

sub supported_parameters { () }
sub default_severity { $SEVERITY_HIGH }
sub default_themes { 'freenode' }
sub applies_to { 'PPI::Statement::Include' }

my %modules = (
	'AnyEvent' => {
		expl => 'AnyEvent\'s author refuses to use public bugtracking and actively breaks interoperability. POE, IO::Async, and Mojo::IOLoop are widely used and interoperable async event loops.',
	},
	'Any::Moose' => {
		expl => 'Any::Moose is deprecated. Use Moo instead.',
	},
	'Class::DBI' => {
		expl => 'Class::DBI is an ancient database ORM abstraction layer which is buggy and abandoned. See DBIx::Class for a more modern DBI-based ORM, or Mad::Mapper for a Mojolicious-style ORM.',
	},
	'CGI' => {
		expl => 'CGI.pm is an ancient module for communicating via the CGI protocol, with tons of bad practices and cruft. Use a modern framework such as those based on Plack (Web::Simple, Dancer2, Catalyst) or Mojolicious, they can still be served via CGI if you choose.',
	},
	'Coro' => {
		expl => 'Coro no longer works on perl 5.22, you need to use the author\'s forked version of Perl. Avoid at all costs.',
	},
	'Error' => {
		expl => 'Error.pm is overly magical and discouraged by its maintainers. Try Throwable for exception classes in Moo/Moose, or Exception::Class otherwise. Try::Tiny or Try are recommended for the try/catch syntax.',
	},
	'File::Slurp' => {
		expl => 'File::Slurp gets file encodings all wrong, line endings on win32 are messed up, and it was written before layers were properly added. Use File::Slurper, Path::Tiny, Data::Munge, or Mojo::File.',
	},
	'Getopt::Std' => {
		expl => 'Getopt::Std was the original very simplistic command-line option processing module. It is now obsoleted by the much more complete solution Getopt::Long, which also supports short options, and is wrapped by module such as Getopt::Long::Descriptive and Getopt::Long::Modern for simpler usage.',
		severity => $SEVERITY_MEDIUM,
	},
	'HTML::Template' => {
		expl => 'HTML::Template is an old and buggy module, try Template Toolkit, HTML::Zoom, or Text::Template instead, or HTML::Template::Pro if you must use the same syntax.',
	},
	'IO::Socket::INET6' => {
		expl => 'IO::Socket::INET6 is an old attempt at an IPv6 compatible version of IO::Socket::INET, but has numerous issues and is discouraged by the maintainer in favor of IO::Socket::IP, which transparently creates IPv4 and IPv6 sockets.',
	},
	'JSON' => {
		expl => 'JSON.pm is old and full of slow logic. Use JSON::MaybeXS instead, it is a drop-in replacement in most cases.',
		severity => $SEVERITY_MEDIUM,
	},
	'JSON::Any' => {
		expl => 'JSON::Any is deprecated. Use JSON::MaybeXS instead.',
	},
	'JSON::XS' => {
		expl => 'JSON::XS\'s author refuses to use public bugtracking and actively breaks interoperability. Cpanel::JSON::XS is a fork with several bugfixes and a more collaborative maintainer. See also JSON::MaybeXS.',
	},
	'List::MoreUtils' => {
		expl => 'List::MoreUtils is a far more complex distribution than it needs to be. Use List::SomeUtils instead, or see List::Util or List::UtilsBy for alternatives.',
		severity => $SEVERITY_LOW,
	},
	'Mouse' => {
		expl => 'Mouse was created to be a faster version of Moose, a niche that has since been better filled by Moo. Use Moo instead.',
		severity => $SEVERITY_LOW,
	},
	'Net::IRC' => {
		expl => 'Net::IRC is an ancient module implementing the IRC protocol. Use a modern event-loop-based module instead. Choices are POE::Component::IRC (and Bot::BasicBot based on that), Net::Async::IRC, and Mojo::IRC.',
	},
	'Readonly' => {
		expl => 'Readonly.pm is buggy and slow. Use Const::Fast or ReadonlyX instead, or the core pragma constant.',
		severity => $SEVERITY_MEDIUM,
	},
	'Switch' => {
		expl => 'Switch.pm is a buggy and outdated source filter which can cause any number of strange errors, in addition to the problems with smart-matching shared by its replacement, the \'switch\' feature (given/when). Try Switch::Plain instead.',
	},
	'XML::Simple' => {
		expl => 'XML::Simple tries to coerce complex XML documents into perl data structures. This leads to overcomplicated structures and unexpected behavior. Use a proper DOM parser instead like XML::LibXML, XML::TreeBuilder, XML::Twig, or Mojo::DOM.',
	},
);

sub _violation {
	my ($self, $module, $elem) = @_;
	my $desc = "Used module $module";
	my $expl = $modules{$module}{expl} // "Module $module is discouraged.";
	my $severity = $modules{$module}{severity} // $self->default_severity;
	return Perl::Critic::Violation->new($desc, $expl, $elem, $severity);
}

sub violates {
	my ($self, $elem) = @_;
	return () unless defined $elem->module and exists $modules{$elem->module};
	return $self->_violation($elem->module, $elem);
}

1;

=head1 NAME

Perl::Critic::Policy::Freenode::DiscouragedModules - Various modules
discouraged from use

=head1 DESCRIPTION

Various modules are discouraged by the denizens of #perl on Freenode IRC, for
various reasons which may include: buggy behavior, cruft, maintainer issues,
or simply better modern replacements.

=head1 MODULES

=head2 AnyEvent

L<AnyEvent>'s author refuses to use public bugtracking and actively breaks
interoperability. L<POE>, L<IO::Async>, and L<Mojo::IOLoop> are widely used and
interoperable async event loops.

=head2 Any::Moose

L<Any::Moose> is deprecated. Use L<Moo> instead.

=head2 Class::DBI

L<Class::DBI> is an ancient database L<ORM|https://en.wikipedia.org/wiki/Object-relational_mapping>
abstraction layer which is buggy and abandoned. See L<DBIx::Class> for a more
modern L<DBI>-based ORM, or L<Mad::Mapper> for a L<Mojolicious>-style ORM.

=head2 CGI

L<CGI>.pm is an ancient module for communicating via the CGI protocol, with
tons of bad practices and cruft. Use a modern framework such as those based on
L<Plack> (L<Web::Simple>, L<Dancer2>, L<Catalyst>) or L<Mojolicious>, they can
still be served via CGI if you choose.

=head2 Coro

L<Coro> no longer works on perl 5.22, you need to use the author's forked
version of Perl. Avoid at all costs.

=head2 Error

L<Error>.pm is overly magical and discouraged by its maintainers. Try
L<Throwable> for exception classes in L<Moo>/L<Moose>, or L<Exception::Class>
otherwise. L<Try::Tiny> or L<Try> are recommended for the C<try>/C<catch>
syntax.

=head2 File::Slurp

L<File::Slurp> gets file encodings all wrong, line endings on win32 are messed
up, and it was written before layers were properly added. Use L<File::Slurper>,
L<Path::Tiny/"slurp">, L<Data::Munge/"slurp">, or L<Mojo::File/"slurp">.

=head2 Getopt::Std

L<Getopt::Std> was the original very simplistic command-line option processing
module. It is now obsoleted by the much more complete solution L<Getopt::Long>,
which also supports short options, and is wrapped by modules such as
L<Getopt::Long::Descriptive> and L<Getopt::Long::Modern> for simpler usage.

=head2 HTML::Template

L<HTML::Template> is an old and buggy module, try L<Template::Toolkit>,
L<HTML::Zoom>, or L<Text::Template> instead, or L<HTML::Template::Pro> if you
must use the same syntax.

=head2 IO::Socket::INET6

L<IO::Socket::INET6> is an old attempt at an IPv6 compatible version of
L<IO::Socket::INET>, but has numerous issues and is discouraged by the
maintainer in favor of L<IO::Socket::IP>, which transparently creates IPv4 and
IPv6 sockets.

=head2 JSON

L<JSON>.pm is old and full of slow logic. Use L<JSON::MaybeXS> instead, it is a
drop-in replacement in most cases.

=head2 JSON::Any

L<JSON::Any> is deprecated. Use L<JSON::MaybeXS> instead.

=head2 JSON::XS

L<JSON::XS>'s author refuses to use public bugtracking and actively breaks
interoperability. L<Cpanel::JSON::XS> is a fork with several bugfixes and a
more collaborative maintainer. See also L<JSON::MaybeXS>.

=head2 List::MoreUtils

L<List::MoreUtils> is a far more complex distribution than it needs to be. Use
L<List::SomeUtils> instead, or see L<List::Util> or L<List::UtilsBy> for
alternatives.

=head2 Mouse

L<Mouse> was created to be a faster version of L<Moose>, a niche that has since
been better filled by L<Moo>. Use L<Moo> instead.

=head2 Net::IRC

L<Net::IRC> is an ancient module implementing the IRC protocol. Use a modern
event-loop-based module instead. Choices are L<POE::Component::IRC> (used for
L<Bot::BasicBot>), L<Net::Async::IRC>, and L<Mojo::IRC>.

=head2 Readonly

L<Readonly>.pm is buggy and slow. Use L<Const::Fast> or L<ReadonlyX> instead,
or the core pragma L<constant>.

=head2 Switch

L<Switch>.pm is a buggy and outdated source filter which can cause any number
of strange errors, in addition to the problems with smart-matching shared by
its replacement, L<feature/"The 'switch' feature"> (C<given>/C<when>). Try
L<Switch::Plain> instead.

=head2 XML::Simple

L<XML::Simple> tries to coerce complex XML documents into perl data structures.
This leads to overcomplicated structures and unexpected behavior. Use a proper
DOM parser instead like L<XML::LibXML>, L<XML::TreeBuilder>, L<XML::Twig>, or
L<Mojo::DOM>.

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
