package Perl::Critic::Policy::Freenode::PackageMatchesFilename;

use strict;
use warnings;

use Perl::Critic::Utils qw(:severities :classification :ppi);
use Path::Tiny 'path';
use parent 'Perl::Critic::Policy';

our $VERSION = '0.027';

use constant DESC => 'No package matching the module filename';
use constant EXPL => 'A Perl module file is expected to contain a matching package name, so it can be used after loading it from the filesystem. A module file that doesn\'t contain a matching package name usually indicates an error.';

sub default_severity { $SEVERITY_HIGH }
sub default_themes { 'freenode' }
sub applies_to { 'PPI::Document' }

sub violates {
	my ($self, $elem, $doc) = @_;
	return () unless $doc->is_module and $doc->filename and $doc->filename =~ m/\.pm\z/;
	
	my $packages = $elem->find('PPI::Statement::Package') || [];
	
	my $filepath = path($doc->filename)->realpath;
	my $basename = $filepath->basename(qr/\.pm/);
	$filepath = $filepath->parent->child($basename);
	
	my $found_match;
	PKG: foreach my $package (@$packages) {
		my $namespace = $package->namespace;
		my $path_copy = $filepath;
		foreach my $part (reverse split '::', $namespace) {
			next PKG unless $part eq $path_copy->basename;
			$path_copy = $path_copy->parent;
		}
		$found_match = 1;
		last;
	}
	
	return () if $found_match;
	return $self->violation(DESC, EXPL, $elem);
}

1;

=head1 NAME

Perl::Critic::Policy::Freenode::PackageMatchesFilename - Module files should
declare a package matching the filename

=head1 DESCRIPTION

Perl modules are normally loaded by C<require> (possibly via C<use> or C<no>).
When given a module name, C<require> will translate this into a filename and
then load whatever that file contains. The file doesn't need to actually
contain a package matching the module name initially given to C<require>, but
this can be confusing if later operations (including C<import> as called by
C<use>) expect the package to exist. Furthermore, the absence of such a package
is usually an indicator of a typo in the package name.

  ## in file My/Module.pm
  package My::Module;

This policy is similar to the core policy
L<Perl::Critic::Policy::Modules::RequireFilenameMatchesPackage>, but only
requires that one package name within a module file matches the filename.

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
