package PkgForge::Types; # -*-perl-*-
use strict;
use warnings;

# $Id: Types.pm.in 16978 2011-05-04 11:32:43Z squinney@INF.ED.AC.UK $
# $Source:$
# $Revision: 16978 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/PkgForge/PkgForge_1_4_8/lib/PkgForge/Types.pm.in $
# $Date: 2011-05-04 12:32:43 +0100 (Wed, 04 May 2011) $

our $VERSION = '1.4.8';

use Email::Address ();
use Email::Valid   ();
use File::Spec     ();

use Moose::Util::TypeConstraints;
use MooseX::Getopt;
use MooseX::Types -declare => [ 'AbsolutePath', 'AbsolutePathDirectory',
                                'EmailAddress', 'EmailAddressList',
                                'NoCommas',     'PkgForgeList',
                                'UserName', 'UID', 'Octal',
                                'SourcePackage', 'SourcePackageList',
                                'SourceBuilder', 'PkgForgeID' ];
use MooseX::Types::Moose qw(Int Str ArrayRef);

subtype SourcePackage,
  as role_type('PkgForge::Source');

subtype SourcePackageList,
  as ArrayRef[SourcePackage];

subtype SourceBuilder,
  as role_type('PkgForge::Builder');

subtype AbsolutePath,
  as Str,
  where { File::Spec->file_name_is_absolute($_) },
  message { 'Must be an absolute path.' };

# coerce the input string (which is possibly a relative path) into an
# absolute path which does not have a trailing /

coerce AbsolutePath,
  from Str,
  via {  my $path = File::Spec->file_name_is_absolute($_) ? $_ : File::Spec->rel2abs($_); $path =~ s{/$}{}; $path };

subtype AbsolutePathDirectory,
  as AbsolutePath,
  where { -d $_ },
  message { 'Must be an absolute path and a directory' };

coerce AbsolutePathDirectory,
  from Str,
  via {  my $path = File::Spec->file_name_is_absolute($_) ? $_ : File::Spec->rel2abs($_); $path =~ s{/$}{}; $path };

subtype EmailAddress,
  as Str,
  where { Email::Valid->address( -address => $_ ) },
  message { "Address ($_) for report must be a valid email address" };

subtype EmailAddressList, as ArrayRef[EmailAddress];

coerce EmailAddressList, from Str, via { [ map { $_->format } Email::Address->parse($_)] };

coerce EmailAddressList, from ArrayRef,
  via { [ map { $_->format } map { Email::Address->parse($_) } @{$_} ] };

subtype UserName,
  as Str,
  where { !/^\d+$/ };

coerce UserName,
  from Str,
  via { getpwuid($_) };

subtype UID,
  as Int,
  message { "$_ is not a UID" };

coerce UID,
  from Str,
  via { getpwnam($_) };

subtype Octal,
  as Str,
  where { m/^0\d*$/ };

# This is all so we can supply a referemce to a list where some
# elements may contain a comma-separated list and everything will be
# expanded.

subtype NoCommas,
  as Str,
  where { !m/,/ },
  message { "$_ must not contain any commas" };

subtype PkgForgeList,
  as ArrayRef[NoCommas];

coerce PkgForgeList,
  from ArrayRef,
  via { return [ map { split /\s*,\s*/, $_ } @{$_} ] };

coerce PkgForgeList,
  from Str,
  via { return [ split /\s*,\s*/, $_ ] };

subtype PkgForgeID,
  as Str,
  where { m/^[A-Za-z0-9_.-]+$/ },
  message { 'Identifier can only contain characters matching [A-Za-z0-9_-]' };

1;
__END__

=head1 NAME

    PkgForge::Types - Moose types for the LCFG Package Forge

=head1 VERSION

    This documentation refers to PkgForge::Types version 1.4.8

=head1 SYNOPSIS

    use PkgForge::Types qw(AbsolutePathDirectory);

    has 'directory' => (
       is       => 'rw',
       isa      => AbsolutePathDirectory,
       coerce   => 1,
       required => 1,
       default  => sub { File::Spec->curdir() },
    );

=head1 DESCRIPTION

This module provides various useful Moose types and associated
coercions that are needed in the LCFG Package Forge suite.

=head1 TYPES

=over 4

=item AbsolutePath

A type based on the Moose string type (Str) which requires it to be an
absolute path. There is an associated coercion which can be used to
promote a relative path to an absolute path.

=item AbsolutePathDirectory

A type based on the AbsolutePath type which also requires it to be a
directory. Again there is an associated coercion to promote a relative
path to absolute.

=item EmailAddress

A type based on the Moose string type (Str) which requires it to be a
valid email address. The L<Email::Valid> module is required to do the
validation.

=item EmailAddressList

This list type is based on the Moose ArrayRef type with the
requirement that all elements are of the C<EmailAddress> type.

=item UserName

This is a string type which represents a user name. Anything which is
NOT just a sequence of digits (i.e. looks like a UID) will be
allowed. If a UID is passed in it will be passed through the
C<getpwuid> function to retrieve the associated username.

=item UID

This is an integer type which represents a user ID (UID). Anything
which is not an integer will be passed through the C<getpwnam>
function to retrieve the associated UID.

=item Octal

This is a string type which represents an octal number. It expects the
string to start with a zero followed by a sequence of digits. This is
aimed at attributes which represent Unix file permission modes.

=item NoCommas

This type is based on the Moose string type (Str) which requires that
the string does not contain any commas.

=item PkgForgeList

This type is based on the Moose ArrayRef type with the requirement
that each element is of the C<NoCommas> type. The interesting aspect
of this type is the associated coercions from Str and ArrayRef
types. When coercing from a string it will be split on commas and the
resulting list will be used. When coercing from a list each element
will be passed through the same string coercion to split on commas.

=back

=head1 SUBROUTINES/METHODS

This module does not provide any subroutines or methods.

=head1 DEPENDENCIES

This module is L<Moose> powered and uses L<MooseX::Types>. It also
requires L<Email::Address> and L<Email::Valid>.

=head1 SEE ALSO

L<PkgForge>

=head1 PLATFORMS

This is the list of platforms on which we have tested this
software. We expect this software to work on any Unix-like platform
which is supported by Perl.

ScientificLinux5, Fedora13

=head1 BUGS AND LIMITATIONS

Please report any bugs or problems (or praise!) to bugs@lcfg.org,
feedback and patches are also always very welcome.

=head1 AUTHOR

    Stephen Quinney <squinney@inf.ed.ac.uk>

=head1 LICENSE AND COPYRIGHT

    Copyright (C) 2010-2011 University of Edinburgh. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the terms of the GPL, version 2 or later.

=cut
