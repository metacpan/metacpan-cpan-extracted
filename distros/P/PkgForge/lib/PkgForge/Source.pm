package PkgForge::Source; # -*-perl-*-
use strict;
use warnings;

# $Id: Source.pm.in 16195 2011-02-28 20:38:11Z squinney@INF.ED.AC.UK $
# $Source:$
# $Revision: 16195 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/PkgForge/PkgForge_1_4_8/lib/PkgForge/Source.pm.in $
# $Date: 2011-02-28 20:38:11 +0000 (Mon, 28 Feb 2011) $

our $VERSION = '1.4.8';

use Digest::SHA1 ();
use English qw(-no_match_vars);
use File::stat ();
use File::Spec ();
use IO::File ();

use Moose::Role;
use PkgForge::Meta::Attribute::Trait::Serialise;
use PkgForge::Types qw(AbsolutePathDirectory);
use MooseX::Types::Moose qw(Int Str);
use Moose::Util::TypeConstraints;

requires 'validate';

subtype 'FileNameOnly'
    => as Str
    => where { $_ eq (File::Spec->splitpath($_))[2] }
    => message { 'Must be a file name.' };

# coerce the input string (which is possibly a relative path) into an
# absolute path which does not have a trailing /

coerce 'FileNameOnly'
    => from Str
    => via { (File::Spec->splitpath($_))[2] };

has 'type' => (
    traits   => ['PkgForge::Serialise'],
    is       => 'ro',
    isa      => Str,
    required => 1,
    default  => sub { my ($self) = @_;
                      return ( split /::/, $self->meta->name )[-1] },
);

has 'basedir' => (
    is       => 'rw',
    isa      => AbsolutePathDirectory,
    coerce   => 1,
    lazy     => 1,
    default  => sub { File::Spec->curdir() },
);

has 'file' => (
    traits   => ['PkgForge::Serialise'],
    is       => 'ro',
    isa      => 'FileNameOnly',
    required => 1,
    documentation => 'The path to the source package',
);

has 'size' => (
    traits   => ['PkgForge::Serialise'],
    is       => 'ro',
    isa      => Int,
    builder  => '_file_size',
    lazy     => 1,
    documentation => 'The size of the source package in bytes',
);

sub _file_size {
    my ($self) = @_;

    my $path = $self->fullpath;
    if ( !-e $path ) {
        return 0;
    } else {
        return File::stat::stat($path)->size;
    }
}

has 'sha1sum' => (
    traits   => ['PkgForge::Serialise'],
    is       => 'ro',
    isa      => Str,
    builder  => 'gen_sha1sum',
    lazy     => 1,
    documentation => 'The SHA1 checksum for the source package',
);

around 'BUILDARGS' => sub {
    my $orig  = shift;
    my $class = shift;

    if ( @_ == 1 && ! ref $_[0] ) {
        my ( $vol, $dir, $file ) = File::Spec->splitpath($_[0]);
        return $class->$orig(
            basedir => $dir,
            file    => $file
        );
    }
    else {
        return $class->$orig(@_);
    }
};

sub fullpath {
    my ($self) = @_;

    return File::Spec->catfile( $self->basedir, $self->file );
}

sub gen_sha1sum {
    my ($self) = @_;

    my $file = $self->fullpath;

    my $fh = IO::File->new( $file, 'r' )
        or die "Could not open $file: $OS_ERROR\n";

    my $sha1 = Digest::SHA1->new();

    $sha1->addfile($fh);

    return $sha1->hexdigest;
}

sub check_sha1sum {
    my ($self) = @_;

    my $sum = $self->gen_sha1sum;

    return $sum eq $self->sha1sum;
}

sub can_handle {
    my ( $class, $file ) = @_;

    if ( !defined $file ) {
        die "You must specify a file name to verify\n";
    }

    my $ok = eval { $class->validate($file) };

    return ( $ok ? 1 : 0 );
}

no Moose::Role;
1;
__END__

=head1 NAME

     PkgForge::Source - A source package class for the LCFG Package Forge

=head1 VERSION

     This documentation refers to PkgForge::Source version 1.4.8

=head1 SYNOPSIS

     This is a Moose role and cannot be instantiated directly. Use it
     as shown below, note that you are required to implement an
     instance method named C<validate>.

     package PkgForge::Source::SRPM;

     use Moose;

     with 'PkgForge::Source';

     sub validate { }

=head1 DESCRIPTION

This module provides a representation of a source package which is
used by the LCFG Package Forge software suite. It is not intended to
be comprehensive but rather to just fulfill the simple requirements
for representing build jobs.

A source package can be anything, it could be a source tar file or an
SRPM for example.

=head1 ATTRIBUTES

=over 4

=item basedir

This is the directory in which the source package can be found. If
none is given then it defaults to the current directory. The directory
must exist.

=item file

This is the file name of the source package, this attribute is
required when creating new objects. It is not required for the file to
exist but you will need it if you want to find the sha1sum or carry
out validation tests.

=item sha1sum

This is the SHA1 checksum of the source package. It will be calculated
the first time the attribute is queried.

=item size

This is the size of the source package, measured in bytes. If the file
does not exist then this will be zero.

=item type

This is a string representing the type of the source package. It is
the final part of the name of the module which implements this
role. For example, for "PkgForge::Source::SRPM" the type is
"SRPM".

=back

=head1 SUBROUTINES/METHODS

=head2 Class Methods

There is one class method.

=over

=item can_handle($file)

This class method takes the path to a source file. It returns true or
false based on whether or not the module can handle that type of
source file. It uses the C<validate> method to do the working of
checking the source package. Note that under normal circumstances
(i.e. when checking the source package validity) this method must not
die.

=head2 Instance Methods

There are several instance methods.

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

=item fullpath

This returns the full path to the source package (i.e. the combination
of the C<basedir> and C<file> attributes).

=item validate($file)

This will carry out type-specific validation (e.g. for SRPM we would
ensure that it really is a proper SRPM not just something with a
C<.src.rpm> suffix). This method must be provided by all classes
implementing this role. It will take either a file name as an argument
or use the C<fullpath> method.

=back

=head1 DEPENDENCIES

This module is powered by L<Moose> and also uses L<MooseX::Types> and
L<Digest::SHA1>.

=head1 SEE ALSO

L<PkgForge>, L<PkgForge::Job>, L<PkgForge::Types>,
L<PkgForge::Source::SRPM>

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
