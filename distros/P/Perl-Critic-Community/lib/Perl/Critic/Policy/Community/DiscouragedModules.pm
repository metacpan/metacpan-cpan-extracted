package Perl::Critic::Policy::Community::DiscouragedModules;

use strict;
use warnings;

use Perl::Critic::Utils qw(:severities :classification :ppi);
use parent 'Perl::Critic::Policy';

our $VERSION = 'v1.0.2';

sub supported_parameters {
	(
		{
			name            => 'allowed_modules',
			description     => 'Modules that you want to allow, despite being discouraged.',
			behavior        => 'string list',
		},
	)
}
sub default_severity { $SEVERITY_HIGH }
sub default_themes { 'community' }
sub applies_to { 'PPI::Statement::Include' }

my %modules = (
	'AnyEvent' => 'AnyEvent\'s author refuses to use public bugtracking and actively breaks interoperability. POE, IO::Async, and Mojo::IOLoop are widely used and interoperable async event loops.',
	'Any::Moose' => 'Any::Moose is deprecated. Use Moo instead.',
	'Class::DBI' => 'Class::DBI is an ancient database ORM abstraction layer which is buggy and abandoned. See DBIx::Class for a more modern DBI-based ORM, or Mad::Mapper for a Mojolicious-style ORM.',
	'CGI' => 'CGI.pm is an ancient module for communicating via the CGI protocol, with tons of bad practices and cruft. Use a modern framework such as those based on Plack (Web::Simple, Dancer2, Catalyst) or Mojolicious, they can still be served via CGI if you choose. Use CGI::Tiny if you are limited to the CGI protocol.',
	'Coro' => 'Coro abuses Perl internals in an unsupported way. Consider Future and Future::AsyncAwait in combination with event loops for similar semantics.',
	'Error' => 'Error.pm is overly magical and discouraged by its maintainers. Try Throwable for exception classes in Moo/Moose, or Exception::Class otherwise. Try::Tiny or Syntax::Keyword::Try are recommended for the try/catch syntax.',
	'File::Slurp' => 'File::Slurp gets file encodings all wrong, line endings on win32 are messed up, and it was written before layers were properly added. Use File::Slurper, Path::Tiny, Data::Munge, or Mojo::File.',
	'FindBin' => 'FindBin depends on the sometimes vague definition of "initial script" and can\'t be updated to fix bugs in old Perls. Use Path::This or lib::relative to work with the absolute path of the current source file instead.',
	'HTML::Template' => 'HTML::Template is an old and buggy module, try Template Toolkit, Mojo::Template, or Text::Xslate instead, or HTML::Template::Pro if you must use the same syntax.',
	'IO::Socket::INET6' => 'IO::Socket::INET6 is an old attempt at an IPv6 compatible version of IO::Socket::INET, but has numerous issues and is discouraged by the maintainer in favor of IO::Socket::IP, which transparently creates IPv4 and IPv6 sockets.',
	'IP::World' => 'IP::World is deprecated as its databases are in one case discontinued, in the other no longer updated. Therefore its accuracy is ever-decreasing. Try GeoIP2 instead.',
	'JSON::Any' => 'JSON::Any is deprecated. Use JSON::MaybeXS instead.',
	'JSON::XS' => 'JSON::XS\'s author refuses to use public bugtracking and actively breaks interoperability. Cpanel::JSON::XS is a fork with several bugfixes and a more collaborative maintainer. See also JSON::MaybeXS.',
	'Net::IRC' => 'Net::IRC is an ancient module implementing the IRC protocol. Use a modern event-loop-based module instead. Choices are POE::Component::IRC (and Bot::BasicBot based on that), Net::Async::IRC, and Mojo::IRC.',
	'Switch' => 'Switch.pm is a buggy and outdated source filter which can cause any number of strange errors, in addition to the problems with smart-matching shared by its replacement, the \'switch\' feature (given/when). Try Switch::Plain or Syntax::Keyword::Match instead.',
	'XML::Simple' => 'XML::Simple tries to coerce complex XML documents into perl data structures. This leads to overcomplicated structures and unexpected behavior. Use a proper DOM parser instead like XML::LibXML, XML::TreeBuilder, XML::Twig, or Mojo::DOM.',
);

sub _violation {
	my ($self, $module, $elem) = @_;
	my $desc = "Used module $module";
	my $expl = $modules{$module} // "Module $module is discouraged.";
	return $self->violation($desc, $expl, $elem);
}

sub violates {
	my ($self, $elem) = @_;
	return () unless defined $elem->module and exists $modules{$elem->module} and not exists $self->{_allowed_modules}{$elem->module};
	return $self->_violation($elem->module, $elem);
}

1;

=head1 NAME

Perl::Critic::Policy::Community::DiscouragedModules - Various modules
discouraged from use

=head1 DESCRIPTION

Various modules are discouraged by some subsets of the community, for various
reasons which may include: buggy behavior, cruft, performance problems,
maintainer issues, or simply better modern replacements. This is a high
severity complement to
L<Perl::Critic::Policy::Community::PreferredAlternatives>.

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
still be served via CGI if you choose. Use L<CGI::Tiny> if you are limited to
the CGI protocol.

=head2 Coro

L<Coro> abuses Perl internals in an unsupported way. Consider L<Future> and
L<Future::AsyncAwait> in combination with event loops for similar semantics.

=head2 Error

L<Error>.pm is overly magical and discouraged by its maintainers. Try
L<Throwable> for exception classes in L<Moo>/L<Moose>, or L<Exception::Class>
otherwise. L<Try::Tiny> or L<Syntax::Keyword::Try> are recommended for the
C<try>/C<catch> syntax.

=head2 FindBin

L<FindBin> is often used to retrieve the absolute path to the directory
containing the initially executed script, a mechanism which is not always
logically clear. Additionally, it has serious bugs on old Perls and can't be
updated from CPAN to fix them. The L<Path::This> module provides similar
variables and constants based on the absolute path to the current source file.
The L<lib::relative> module resolves passed relative paths to the current
source file for the common case of adding local module include directories.
Each of these documents examples of achieving the same behavior with core
modules.

=head2 File::Slurp

L<File::Slurp> gets file encodings all wrong, line endings on win32 are messed
up, and it was written before layers were properly added. Use L<File::Slurper>,
L<Path::Tiny/"slurp">, L<Data::Munge/"slurp">, or L<Mojo::File/"slurp">.

=head2 HTML::Template

L<HTML::Template> is an old and buggy module, try L<Template::Toolkit>,
L<Mojo::Template>, or L<Text::Xslate> instead, or L<HTML::Template::Pro> if you
must use the same syntax.

=head2 IO::Socket::INET6

L<IO::Socket::INET6> is an old attempt at an IPv6 compatible version of
L<IO::Socket::INET>, but has numerous issues and is discouraged by the
maintainer in favor of L<IO::Socket::IP>, which transparently creates IPv4 and
IPv6 sockets.

=head2 IP::World

L<IP::World> was built from two free publicly available databases. However, over
the years one of them was discontinued, and the other is no longer being updated.
Therefore the module's accuracy is ever-decreasing. Try L<GeoIP2> as an alternative.
That code is I<also> deprecated, but at least its database is still updated.

=head2 JSON::Any

L<JSON::Any> is deprecated. Use L<JSON::MaybeXS> instead.

=head2 JSON::XS

L<JSON::XS>'s author refuses to use public bugtracking and actively breaks
interoperability. L<Cpanel::JSON::XS> is a fork with several bugfixes and a
more collaborative maintainer. See also L<JSON::MaybeXS>.

=head2 Net::IRC

L<Net::IRC> is an ancient module implementing the IRC protocol. Use a modern
event-loop-based module instead. Choices are L<POE::Component::IRC> (used for
L<Bot::BasicBot>), L<Net::Async::IRC>, and L<Mojo::IRC>.

=head2 Switch

L<Switch>.pm is a buggy and outdated source filter which can cause any number
of strange errors, in addition to the problems with smart-matching shared by
its replacement, L<feature/"The 'switch' feature"> (C<given>/C<when>). Try
L<Switch::Plain> or L<Syntax::Keyword::Match> instead.

=head2 XML::Simple

L<XML::Simple> tries to coerce complex XML documents into perl data structures.
This leads to overcomplicated structures and unexpected behavior. Use a proper
DOM parser instead like L<XML::LibXML>, L<XML::TreeBuilder>, L<XML::Twig>, or
L<Mojo::DOM>.

=head1 AFFILIATION

This policy is part of L<Perl::Critic::Community>.

=head1 CONFIGURATION

Occasionally you may find yourself needing to use one of these discouraged
modules, and do not want the warnings.  You can do so by putting something like
the following in a F<.perlcriticrc> file like this:

    [Community::DiscouragedModules]
    allowed_modules = FindBin Any::Moose

The same option is offered for L<Perl::Critic::Policy::Community::PreferredAlternatives>.

=head1 AUTHOR

Dan Book, C<dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2015, Dan Book.

This library is free software; you may redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<Perl::Critic>
