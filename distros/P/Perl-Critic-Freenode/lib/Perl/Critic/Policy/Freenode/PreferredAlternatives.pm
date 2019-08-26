package Perl::Critic::Policy::Freenode::PreferredAlternatives;

use strict;
use warnings;

use Perl::Critic::Utils qw(:severities :classification :ppi);
use parent 'Perl::Critic::Policy';

our $VERSION = '0.030';

sub supported_parameters { () }
sub default_severity { $SEVERITY_LOW }
sub default_themes { 'freenode' }
sub applies_to { 'PPI::Statement::Include' }

my %modules = (
	'Getopt::Std' => 'Getopt::Std was the original very simplistic command-line option processing module. It is now obsoleted by the much more complete solution Getopt::Long, which also supports short options, and is wrapped by module such as Getopt::Long::Descriptive and Getopt::Long::Modern for simpler usage.',
	'JSON' => 'JSON.pm is old and full of slow logic. Use JSON::MaybeXS instead, it is a drop-in replacement in most cases.',
	'List::MoreUtils' => 'List::MoreUtils is a far more complex distribution than it needs to be. Use List::SomeUtils instead, or see List::Util or List::UtilsBy for alternatives.',
	'Mouse' => 'Mouse was created to be a faster version of Moose, a niche that has since been better filled by Moo. Use Moo instead.',
	'Readonly' => 'Readonly.pm is buggy and slow. Use Const::Fast or ReadonlyX instead, or the core pragma constant.',
);

sub _violation {
	my ($self, $module, $elem) = @_;
	my $desc = "Used module $module";
	my $expl = $modules{$module} // "Module $module has preferred alternatives.";
	return $self->violation($desc, $expl, $elem);
}

sub violates {
	my ($self, $elem) = @_;
	return () unless defined $elem->module and exists $modules{$elem->module};
	return $self->_violation($elem->module, $elem);
}

1;

=head1 NAME

Perl::Critic::Policy::Freenode::PreferredAlternatives - Various modules with
preferred alternatives

=head1 DESCRIPTION

Various modules have alternatives that are preferred by the denizens of #perl
on Freenode IRC, for various reasons which may include: buggy behavior, cruft,
performance problems, maintainer issues, or simply better modern replacements.
This is a low severity complement to
L<Perl::Critic::Policy::Freenode::DiscouragedModules>.

=head1 MODULES

=head2 Getopt::Std

L<Getopt::Std> was the original very simplistic command-line option processing
module. It is now obsoleted by the much more complete solution L<Getopt::Long>,
which also supports short options, and is wrapped by modules such as
L<Getopt::Long::Descriptive> and L<Getopt::Long::Modern> for simpler usage.

=head2 JSON

L<JSON>.pm is old and full of slow logic. Use L<JSON::MaybeXS> instead, it is a
drop-in replacement in most cases.

=head2 List::MoreUtils

L<List::MoreUtils> is a far more complex distribution than it needs to be. Use
L<List::SomeUtils> instead, or see L<List::Util> or L<List::UtilsBy> for
alternatives.

=head2 Mouse

L<Mouse> was created to be a faster version of L<Moose>, a niche that has since
been better filled by L<Moo>. Use L<Moo> instead.

=head2 Readonly

L<Readonly>.pm is buggy and slow. Use L<Const::Fast> or L<ReadonlyX> instead,
or the core pragma L<constant>.

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
