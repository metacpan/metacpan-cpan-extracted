package PkgForge::Source::SRPM; # -*-perl-*-
use strict;
use warnings;

# $Id: SRPM.pm.in 15901 2011-02-16 16:05:28Z squinney@INF.ED.AC.UK $
# $Source:$
# $Revision: 15901 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/PkgForge/PkgForge_1_4_8/lib/PkgForge/Source/SRPM.pm.in $
# $Date: 2011-02-16 16:05:28 +0000 (Wed, 16 Feb 2011) $

our $VERSION = '1.4.8';

use Moose;

with 'PkgForge::Source';

use overload q{""} => sub { shift->fullpath };

no Moose;
__PACKAGE__->meta->make_immutable;

sub validate {
    my ( $self, $file ) = @_;

    $file ||= $self->fullpath;

    if ( $file !~ m/\.src\.rpm$/ ) {
        die "The SRPM file name must end with .src.rpm\n";
    }

    if ( !-f $file ) {
        die "The SRPM file '$file' does not exist\n";
    }

    require RPM2;

    my $hdr = eval { RPM2->open_package($file) };
    if ( !$hdr || $@ || !$hdr->is_source_package ) {
        die "The file '$file' is not an SRPM\n";
    }
    if ( !grep { m/\.spec$/ } $hdr->files ) {
        die "The SRPM '$file' does not contain a file which matches '*.spec'\n";
    }

    return 1;
}

1;
__END__

=head1 NAME

PkgForge::Source::SRPM - A source RPM class for the LCFG Package Forge

=head1 VERSION

This documentation refers to PkgForge::Source::SRPM version 1.4.8

=head1 SYNOPSIS

     use PkgForge::Source::SRPM;

     my $pkg = PkgForge::Source::SRPM->new( file => "foo-1-2.src.rpm" );

     my $ok = eval { $pkg->validate() };

     if ( !$ok || $@ ) {
       warn "$pkg failed to validate: $@\n";
     }

=head1 DESCRIPTION

This module provides a representation of a source RPM package which is
used by the LCFG Package Forge software suite.

=head1 ATTRIBUTES

These attributes all come from the interface which this module
implements, there are no overrides.

=over 4

=item basedir

This is the directory in which the source package can be found. If
none is given then it defaults to the current directory. The directory
must exist.

=item file

This is the file name of the source package, this attribute is
required when creating new objects. The file must exist.

=item sha1sum

This is the SHA1 checksum of the source package. It will be calculated
the first time the attribute is queried.

=item type

This is a string representing the type of the source package. It is
the final part of the name of the module which implements this
role. For example, for "PkgForge::Source::SRPM" the type is
"SRPM".

=back

=head1 SUBROUTINES/METHODS

=head2 Class Methods

=item PkgForge::Source::SRPM->can_handle($file)

This class method takes the path to a source file. It returns true or
false based on whether or not the module can handle that type of
source file. It uses the C<validate> method to do the working of
checking the source package. Note that under normal circumstances
(i.e. when checking the source package validity) this method must not
die.

=back

=head2 Instance Methods

=over 4

=item gen_sha1sum

This method generates the SHA1 digest for the package and returns it
in hexadecimal form.  The length of the returned string will be 40 and
it will only contain characters from this set: '0'..'9' and 'a'..'f'.

=item check_sha1sum

This will compare the current value of the SHA1 checksum, as stored in
the C<sha1sum> attribute, against the value found by running
C<gen_sha1sum> on the package. It returns a boolean value reflecting
whether they match.

=item validate($file)

This does the following validity checks:

=over

=item The file must exist.

=item The file must have the '.src.rpm' suffix.

=item It must be a proper source RPM.

=item It must contain a specfile with the '.spec' suffix.

=back

If all tests pass then a true value is returned, otherwise the method
will die with an appropriate message for the failed test. You will
need the L<RPM2> module for this method to work. It will take either a
file name as an argument or use the C<fullpath> method.

=back

=head1 DEPENDENCIES

This module is powered by L<Moose>. It is based on
L<PkgForge::Source>. It requires L<RPM2> to validate an SRPM.

=head1 SEE ALSO

L<PkgForge>, L<PkgForge::Source>

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

    Copyright (C) 2010 University of Edinburgh. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the terms of the GPL, version 2 or later.

=cut
