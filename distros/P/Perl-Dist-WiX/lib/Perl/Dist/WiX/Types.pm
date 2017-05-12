package Perl::Dist::WiX::Types;

=head1 NAME

Perl::Dist::WiX::Types - Public types used in Perl::Dist::WiX.

=head1 VERSION

This document describes Perl::Dist::WiX::Types version 1.500001.

=head1 SYNOPSIS

	use Perl::Dist::WiX::Types qw( ExistingDirectory ExistingFile TemplateObj );

=head1 DESCRIPTION

This module exists to provide Moose types that Perl::Dist::WiX and subclasses can use.

It may be updated or replaced at any time.

=head1 TYPES PROVIDED

=cut

use 5.010;
use MooseX::Types -declare => [ qw(
	  ExistingDirectory ExistingFile TemplateObj
	  _NoDoubleSlashes _NoSpaces _NoForwardSlashes _NoSlashAtEnd _NotRootDir
	  _NoDots
	  ExistingSubdirectory ExistingDirectory_Spaceless
	  ExistingDirectory_SaneSlashes
	  DirectoryRef DirectoryTag
	  ) ];
use MooseX::Types::Moose qw( Str Object ArrayRef );
use MooseX::Types::Path::Class qw( Dir File );
use Template qw();

our $VERSION = '1.500001';
$VERSION =~ s/_//ms;

=head2 ExistingDirectory

	has bar => (
		is => 'ro',
		isa => ExistingDirectory,
		#...
	);


=cut

subtype ExistingDirectory,
  as Dir,
  where { -d "$_" },
  message {'Directory does not exist'};

subtype _NoDoubleSlashes,
  as ExistingDirectory,
  where { "$_" !~ m{\\\\}ms },
  message {'cannot contain two consecutive slashes'};

subtype _NoForwardSlashes,
  as _NoDoubleSlashes,
  where { "$_" !~ m{/}ms },
  message {'Forward slashes are not allowed'};

subtype _NoSlashAtEnd,
  as _NoForwardSlashes,
  where { "$_" !~ m{\\\z}ms },
  message {'Cannot have a slash at the end'};

subtype _NoDots,
  as _NoSlashAtEnd,
  where { "$_" !~ m{[.]}ms },
  message {'Cannot have a period'};

subtype ExistingDirectory_SaneSlashes, as _NoDots;

coerce ExistingDirectory_SaneSlashes,
  from Str,      via { to_Dir($_) },
  from ArrayRef, via { to_Dir($_) };

subtype _NoSpaces,
  as _NoDots,
  where { "$_" !~ m{\s}ms },
  message {'Spaces are not allowed'};

subtype ExistingDirectory_Spaceless, as _NoSpaces;

coerce ExistingDirectory_Spaceless,
  from Str,      via { to_Dir($_) },
  from ArrayRef, via { to_Dir($_) };

subtype _NotRootDir,
  as _NoDots,
  where { "$_" !~ m{:\z}ms },
  message {'Cannot be a root directory'};

subtype ExistingSubdirectory, as _NotRootDir;

coerce ExistingSubdirectory,
  from Str,      via { to_Dir($_) },
  from ArrayRef, via { to_Dir($_) };

=head2 ExistingFile

	has bar => (
		is => 'ro',
		isa => ExistingFile,
		#...
	);


=cut

subtype ExistingFile,
  as File,
  where { -f "$_" },
  message {'File does not exist'};

coerce ExistingFile,
  from Str,      via { to_File($_) },
  from ArrayRef, via { to_File($_) };

=head2 TemplateObj

	has bar => (
		is => 'ro',
		isa => TemplateObj,
		#...
	);


=cut

subtype TemplateObj,
  as Object,
  where { $_->isa('Template') },
  message {'Template is not the correct type of object'};

class_type DirectoryRef, { class => 'Perl::Dist::WiX::Tag::DirectoryRef' };

class_type DirectoryTag, { class => 'Perl::Dist::WiX::Tag::Directory' };

1;

__END__

=pod

=head1 SUPPORT

No support is available for this class.

=head1 AUTHOR

Curtis Jewell E<lt>csjewell@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 - 2011 Curtis Jewell.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this distribution.

=cut
