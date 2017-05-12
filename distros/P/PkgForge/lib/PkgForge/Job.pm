package PkgForge::Job; # -*-perl-*-
use strict;
use warnings;

# $Id: Job.pm.in 17740 2011-06-30 05:10:48Z squinney@INF.ED.AC.UK $
# $Source:$
# $Revision: 17740 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/PkgForge/PkgForge_1_4_8/lib/PkgForge/Job.pm.in $
# $Date: 2011-06-30 06:10:48 +0100 (Thu, 30 Jun 2011) $

our $VERSION = '1.4.8';

use Carp ();
use Data::UUID::Base64URLSafe ();
use English qw(-no_match_vars);
use File::Copy ();
use File::Path ();
use PkgForge::SourceUtils ();
use PkgForge::Utils ();

use overload q{""} => sub { shift->stringify };

use Moose;
use MooseX::Types::Moose qw(Bool Int Str);
use Moose::Util::TypeConstraints;
use PkgForge::Types qw(AbsolutePathDirectory EmailAddressList UserName
                       PkgForgeList SourcePackageList PkgForgeID);

with 'PkgForge::YAMLStorage';

has 'directory' => (
    is  => 'rw',
    isa => AbsolutePathDirectory,
    predicate => 'has_directory',
    documentation => 'The directory in which the job is stored',
);

has 'id' => (
    traits   => ['PkgForge::Serialise'],
    is       => 'rw',
    isa      => PkgForgeID,
    required => 1,
    builder  => 'gen_id',
    documentation => 'The unique identifier for this job',
);

sub gen_id {
    return Data::UUID::Base64URLSafe->new()->create_b64_urlsafe();
}

has 'platforms' => (
    traits     => [ 'Array','PkgForge::Serialise', 'Getopt' ],
    is         => 'rw',
    isa        => PkgForgeList,
    coerce     => 1,
    required   => 1,
    default    => sub { ['auto'] },
    auto_deref => 1,
    handles    => {
        has_no_platforms => 'is_empty',
        filter_platforms => 'grep',
    },
    cmd_aliases => 'p',
    documentation => 'The platforms on which packages should be built',
);

has 'archs' => (
    traits     => [ 'Array', 'PkgForge::Serialise', 'Getopt' ],
    is         => 'rw',
    isa        => PkgForgeList,
    coerce     => 1,
    required   => 1,
    default    => sub { ['all'] },
    auto_deref => 1,
    handles    => {
        has_no_archs => 'is_empty',
        filter_archs => 'grep',
    },
    cmd_aliases => 'a',
    documentation => 'The architectures for which packages should be built',
);

has 'bucket' => (
    traits      => [ 'PkgForge::Serialise', 'Getopt' ],
    is          => 'rw',
    isa         => Str,
    required    => 1,
    cmd_aliases => 'B',
    documentation => 'The bucket to which the packages will be submitted.',
);

has 'subtime' => (
    traits => ['PkgForge::Serialise'],
    is  => 'rw',
    isa => Int,
    documentation => 'The date/time the job was submitted',
);

has 'size' => (
    traits  => ['PkgForge::Serialise'],
    is      => 'rw',
    isa     => Int,
    builder => '_job_size',
    lazy    => 1,
    documentation => 'The total size of the source packages in bytes',
);

sub _job_size {
    my ($self) = @_;

    my $total = 0;
    for my $pkg ($self->packages) {
        $total += $pkg->size;
    }

    return $total;
}

has 'packages' => (
    traits     => [ 'Array', 'PkgForge::Serialise' ],
    is         => 'ro',
    isa        => SourcePackageList,
    auto_deref => 1,
    default    => sub { [] },
    handles    => {
        add_packages    => 'push',
        count_packages  => 'count',
        filter_packages => 'grep',
        packages_list   => 'elements',
    },
    pack       => sub { PkgForge::SourceUtils::pack_packages($_[0]) },
    unpack     => sub { PkgForge::SourceUtils::unpack_packages($_[0]) },
    documentation => 'The set of source packages to be built',
);

after 'add_packages' => sub {
    my ($self) = @_;
    $self->update_job_size;
    return;
};

sub update_job_size {
    my ($self) = @_;

    $self->size( $self->_job_size );

    return;
}

has 'submitter' => (
    traits   => ['PkgForge::Serialise'],
    is       => 'rw',
    isa      => UserName,
    required => 1,
    coerce   => 1,
    default  => sub { getpwuid($<) },
    documentation => 'The name of the person who submitted this job',
);

has 'report' => (
    traits      => ['PkgForge::Serialise','Getopt','Array'],
    is          => 'rw',
    isa         => EmailAddressList,
    coerce      => 1,
    cmd_aliases => 'r',
    predicate   => 'report_required',
    handles     => {
        report_list => 'elements',
    },
    documentation => 'Email addresses to which build reports will be sent',
);

has 'verbose' => (
    traits      => ['Getopt'],
    is          => 'rw',
    isa         => Bool,
    default     => 0,
    documentation => 'Verbose output',
);

around 'new_from_yamlfile' => sub {
  my $orig = shift;
  my $class = shift;

  my $obj = $class->$orig(@_);

  if ( $obj->has_directory ) {
    my $dir = $obj->directory;

    for my $package ($obj->packages_list) {
      $package->basedir($dir);
    }
  }

  return $obj;
};

no Moose;
__PACKAGE__->meta->make_immutable;

sub stringify {
    my ($self) = @_;
    return $self->id;
}

sub clone {
    my ($self) = @_;

    require Storable;
    my $clone = Storable::dclone($self);

    return $clone;
}

sub process_build_targets {
    my ( $self, @available ) = @_;

    my @all;
    my @auto;
    my %targets;
    for my $item (@available) {
      my ( $name, $arch, $auto )
        = ( $item->{name}, $item->{arch}, $item->{auto} );

      push @all, $name;
      push @auto, $name if $auto;

      push @{ $targets{$name} }, $arch;
    }

    my @names = $self->process_platforms( \@all, \@auto );

    my @wanted;
    for my $name (@names) {
        my @archs = $self->process_archs($targets{$name});

        for my $arch (@archs) {
            push @wanted, [ $name, $arch ];
        }
    }

    return @wanted;
}

sub process_platforms {
    my ( $self, $all, $auto ) = @_;

    # Process the selections (anything which is not prefixed with an '!')

    my @additions = $self->filter_platforms( sub { !m/^!/ } );

    my @selected;
    if ( $self->has_no_platforms || scalar @additions == 0 ) {
        @selected = @{$auto};
    }
    else {
        for my $addition (@additions) {
            if ( $addition eq 'all' ) {
                push @selected, @{$all};
            } elsif ( $addition eq 'auto' ) {
                push @selected, @{$auto};
            } else {
                my @matches = grep { lc($_) eq lc($addition) } @{$all};
                push @selected, @matches;
            }
        }
    }

    # Process any deletions

    my @deletions;
    for my $deletion ( $self->filter_platforms( sub { m/^!/ } ) ) {
        $deletion =~ s/^!//;
        push @deletions, $deletion;
    }

    # uniqueify the list and make it easier to handle deletions

    my %result = map { $_ => 1 } @selected;

    # Need to handle the deletions list in a case-insensitive manner

    for my $deletion (@deletions) {
        $deletion = lc $deletion;

        for my $key ( keys %result ) {
            if ( lc($key) eq $deletion ) {
                delete $result{$key};
            }
        }
    }

    return (sort keys %result);
}

sub process_archs {
    my ( $self, $available ) = @_;

    my @deletions;
    for my $deletion ( $self->filter_archs( sub { m/^!/ } ) ) {
        $deletion =~ s/^!//;
        push @deletions, $deletion;
    }

    my @additions = $self->filter_archs( sub { !m/^!/ } );

    my %result;
    if (   $self->has_no_archs
        || scalar @additions == 0 || grep { $_ eq 'all' } @additions ) {
        %result = map { $_ => 1 } @{$available};
    } else {
        for my $addition (@additions) {
            for my $match ( grep { lc($_) eq lc($addition) } @{$available} ) {
                $result{$match} = 1;
            }
        }
    }

    # Need to handle the deletions list in a case-insensitive manner

    for my $deletion (@deletions) {
        $deletion = lc $deletion;

        for my $key ( keys %result ) {
            if ( lc($key) eq $deletion ) {
                delete $result{$key};
            }
        }
    }

    return (sort keys %result);
}

sub validate {
    my ($self) = @_;

    my @packages = $self->packages;

    if ( scalar @packages == 0 ) {
        die "No packages to build\n";
    }

    for my $package (@packages) {
        my $file = $package->file;

        if ( !$package->check_sha1sum ) {
            die "The sha1sum does not match for $file\n";
        }

        my $ok = eval { $package->validate };
        if ( !$ok ) {
            die "File $file is not a valid source package\n";
        }
    }

    return 1;
}

sub transfer {
    my ( $self, $target ) = @_;

    my $id = $self->id;

    my $new_dir = File::Spec->catdir( $target, $id );
    if ( -e $new_dir ) {
        die "It appears that job $id is already transferred\n";
    }

    my $created = eval { File::Path::mkpath($new_dir) };

    if ($EVAL_ERROR) {
        die "Failed to create $new_dir: $EVAL_ERROR\n";
    }
    if ( $created != 1 ) {
        die "Unexpected results from creating $new_dir: created $created directories\n";
    }

    # Doing a clone allows us to update the metadata for the
    # package objects.

    my $new_obj = $self->clone;

    my $ok;
    for my $package ($new_obj->packages) {
        my $fullpath = $package->fullpath;
        if ( $self->verbose ) {
            warn "Copying '$fullpath' to '$new_dir'\n";
        }
        $ok = File::Copy::copy( $fullpath, $new_dir );
        last if !$ok;
        $package->basedir($new_dir);
    }

    if (!$ok) {
        _transfer_failure( $new_dir, "Failed to transfer some packages for job $id" );
    }

    eval {
        my $build_file = File::Spec->catfile( $new_dir, 'build.yml' );
        $new_obj->yamlfile($build_file);
        $new_obj->directory($new_dir);
        $new_obj->store_in_yamlfile();
    };
    if ($EVAL_ERROR) {
        _transfer_failure( $new_dir, "Failed to load transferred job $id" );
    }

    if ( $self->verbose ) {
        warn "Copy finished, will now validate.\n";
    }
    my $valid = eval { $new_obj->validate() };
    if ( !$valid || $EVAL_ERROR ) {
        _transfer_failure( $new_dir, "Failed to validate transfer of job $id" );
    }

    return $new_obj;
}

sub _transfer_failure {
    my ( $dir, $msg ) = @_;

    if ( -d $dir ) {
        PkgForge::Utils::remove_tree($dir);
    }

    die "$msg\n";
}

sub overdue {
    my ( $self, $timeout ) = @_;

    my $now = time;
    return ( ($now - $timeout) > $self->subtime );
}

sub new_from_qentry {
    my ( $class, $qentry ) = @_;

    my $dir = $qentry->path;

    my $obj = $class->new_from_dir($dir);

    # Submitter
    my $uid = $qentry->owner;
    my $owner = getpwuid($uid);
    $obj->submitter( $owner || $uid );

    # Submission time
    $obj->subtime($qentry->timestamp);

    return $obj;
}

sub new_from_dir {
    my ( $class, $dir ) = @_;

    if ( !-d $dir ) {
        die "Build job directory '$dir' does not exist\n";
    }

    my $build_file = File::Spec->catfile( $dir, 'build.yml' );

    if ( !-f $build_file ) {
        die "Build job file '$build_file' does not exist\n";
    }

    return $class->new_from_yamlfile( yamlfile  => $build_file,
                                      directory => $dir );
}

sub scrub {
    my ( $self, $options ) = @_;

    PkgForge::Utils::remove_tree( $self->directory, $options );

    undef $self;

    return;
}

1;
__END__

=head1 NAME

PkgForge::Job - Represents a build job for the LCFG Package Forge

=head1 VERSION

This documentation refers to PkgForge::Job version 1.4.8

=head1 SYNOPSIS

     use PkgForge::Job;
     use PkgForge::Source::SRPM;

     my $job = PkgForge::Job->new( bucket   => "lcfg",
                                   archs    => ["i386","x86_64"],
                                   platform => ["sl5"] );

     my $package =
        PkgForge::Source::SRPM->new( file => "foo-1.2.src.rpm");

     $job->add_packages($package);

     my $ok = eval { $job->validate };
     if ( !$ok || $@ ) {
        die "Invalid job $job: $@\n";
     }

=head1 DESCRIPTION

This module provides a representation of a build job which is used by
the LCFG Package Forge software suite.

It can be used to submit new jobs and also query and validate jobs
which have already been submitted.

The object represents a set of source packages which should be built
as a single build job. It also holds all the information covering the
platforms and architectures on which the packages should be built, the
repository into which the generated binary packages should be
submitted, who submitted the job and when.

=head1 ATTRIBUTES

=over 4

=item platforms

This is the list of platforms for which the set of packages in the job
should be built. By default this list contains just the string C<auto>
and the generated list of platforms is based on those which are active
and listed as being available for adding automatically. If the list
contains the string C<all> then the build will be attempted on all
available platforms.

It is possible to block some platforms to ensure they are
not attempted by prefixing the platform name with C<!> (exclamation
mark). If the list only contains negated platforms then builds will be
attempted on all platforms except those negated. If the list contains
a mixture of platforms and negated platforms then only those requested
will be attempted. If we consider an example where three platforms are
supported, e.g. el5, f12 and f13, here are possible values:

=over

=item C<[ "all" ]> gives C<[ "el5", "f12", "f13" ]>

=item C<[ "all", "!el5" ]> gives C<[ "f12", "f13" ]>

=item C<[ "f12", "f13" ]>  gives C<[ "f12", "f13" ]>

=item C<[ "el5", "!f13" ]> gives C<[ "el5" ]>

=back

Any platform string which is not recognised is ignored.

=item archs

This is the list of architectures for which the set of packages in the
job should be built. If the list contains the string "all" then the
build will be attempted on all available architectures (which is the
default).

In the same way as for the platforms, it is possible to block some
architectures to ensure they are not attempted by prefixing the
platform name with C<!> (exclamation mark). If the list only contains
negated architectures then builds will be attempted on all
architectures except those negated. If the list contains a mixture of
architectures and negated architectures then only those requested will
be attempted. If we consider an example where three architectures are
supported, e.g. i386, x86_64 and ppc, here are possible values:

=over

=item C<[ "all" ]> gives C<[ "i386", "x86_64", "ppc" ]>

=item C<[ "all", "!i386" ]> gives C<[ "x86_64", "ppc" ]>

=item C<[ "x86_64", "ppc" ]>  gives C<[ "x86_64", "ppc" ]>

=item C<[ "i386", "!ppc" ]> gives C<[ "i386" ]>

Note that it is B<NOT> possible to specify a single build job as being
for different sets of architectures on each of the different specified
platforms.

Any architecture string which is not recognised is ignored.

=item bucket

This is the LCFG package bucket into which built packages will be
submitted. This is normally something like "lcfg", "world", "uoe" or
"inf". There is no default value and the bucket C<MUST> be specified.

When building RPMs with mock this bucket is also used to control which
mock configuration file is used. This controls which package
repositories mock has access to for fulfilling build
requirements. This is done to ensure that packages do not have
auto-generated dependency lists which cannot be fulfilled from within
that bucket or the base/updates package repositories.

=item packages

This is a list of source packages for the build job which are to be
built for the set of platforms and architectures. The list takes
objects which implement the PkgForge::Source role. You can
specify as many source packages as you like and mix the types within a
single job. It is left to the individual build daemons to decide
whether they are capable of building from particular types of source
package.

When building RPMs, within a single job, once a package has been built
it becomes available immediately for use as a build-requirement for
the building of subsequent packages. This means that the order in
which the packages are specified is significant. Note that no attempt
is made to solve the build-dependencies for the source packages within
a build job. This extension might be considered at some point in the
future.

A build job is not valid if no packages have been specified.

=item size

This is the total size of the source packages, measured in bytes.

=item report

This is a list of email addresses to which a final report will be
sent. By default no reports are sent.

=item directory

This is the directory in which the packages and the configuration file
for a build job are stored. It does not have to be specified, the
default is assumed to be the current directory where necessary.

=item yamlfile

This is the location of the build job configuration file. This is used
for serialisation of the job object for later reuse. Note that not all
attributes are stored when this is written and not all are read when
it is reloaded. See C<store_in_yamlfile> and C<new_from_yamlfile> for
details.

=item id

This is the UUID for the build job. If none has been specified then a
default value is generated using the L<Data::UUID> module, in which
case the UUID is also converted into base64 and made URL-safe. Any
string which only contains characters matching the set C<A-Za-z0-9_->
is acceptable but beware that if you submit a job with a
user-specified ID and it has previously been used the job will be
rejected.

=item subtime

This is the time of submission for a job, it only really has meaning
from the point-of-view of the build system. Jobs are built in order of
submission time but setting this before submitting a job will not have
any effect on the sequence in which jobs will be built.

=item submitter

This is the user name of the submitter. Currently it is taken from the
ownership of the submitted job directory. If a move was made to
digitally-signed build files then the submitter attribute could
reflect that instead. It is not used for any authorization checks, the
submitter is purely used for tracking jobs so that users can easily
query the status of their own jobs.

=item verbose

This is a boolean value which controls the verbosity of output to
STDERR when class methods are called. By default the methods will not
be verbose.

=back

=head1 SUBROUTINES/METHODS

=over 4

=item clone

This will do a deep clone of a Job object using the C<dclone> function
provided by the L<Storable> module.

=item new()

This will create a new Job object. You must specify the package bucket.

=item new_from_yamlfile( $file, $dir )

This will load an object from the data stored in the meta-file. You
must also specify the directory name, that will then be used to set
the C<directory> attribute for the Job and the C<basedir> attribute
for the Source package objects. Any setting of the C<directory> and
C<yamlfile> attributes in the meta-file are ignored and reset to the
passed in arguments. Only attributes which have the
C<PkgForge::Serialise> trait will be loaded.

=item new_from_dir($dir)

This creates a new Job object based on the meta-file and packages
stored within the specified directory. It uses C<new_from_yamlfile> to
load the meta-file and set the C<directory> attributes appropriately.

=item new_from_qentry($qentry)

This creates a new Job object from the information stored in a
L<PkgForge::Queue::Entry> object. The C<new_from_dir> method is
used with the Queue::Entry C<path> attribute. The C<submitter> and
C<subtime> attributes are set for the Job based on the values in the
Queue::Entry object.

=item overdue($timeout)

This takes a timeout, in seconds, and returns a boolean value which
signifies whether or not the Job is more than that many seconds old.

=item process_build_targets(@platforms)

This takes a list of available, active, platforms, each entry in the
list is a reference to a hash which has values for name, arch and
auto. The arch is the architecture, e.g. C<i386> or C<x86_64>. The
C<auto> value is a boolean which shows whether the platform should be
added automatically or only when explicitly requested.

The method returns a list of requested platforms. Each entry in the
incoming and returned lists is a pair of platform name and
architecture. For example:

    [ ['sl5','i386' ], ['sl5','x86_64'] ]

This is basically just a convenience method with does the work of
C<process_platforms> and C<process_archs> in one step. See the
documentation below for details of how the processing is done.

=item process_platforms(\@all, \@auto)

This method takes references to two lists of platform names. The first
is the complete set of platforms and the second is the set of
platforms which should be added automatically. The two sets may well
be identical. Platforms which are only in the 'auto' set will only be
added if explicitly requested.

This method uses the platform lists to process the rules in the
C<platforms> attribute, it then returns a list of requested
platforms. See the documentation above on the C<platforms> attribute
for full details on how to write the rules.

For example, if the C<platforms> attribute is set to:

    [ "all", "!el5" ]

and the platforms list passed in as an argument is:

    ( "el5", "f12" )

then the returned list is:

    ("f12")

=item process_archs(\@archs)

This takes a reference to a list of available archs and uses them to
process the rules in the C<archs> attribute, it then returns a list of
requested archs. See the documentation above on the C<archs> attribute
for full details on how to write the rules.

For example, if the C<archs> attribute is set to:

    [ "all", "!i386" ]

and the archs list passed in as an argument is:

    ( "i386", "x86_64" )

then the returned list is:

    ("x86_64")

=item store_in_yamlfile([$file])

This will save an object to the meta-file. If the file name is not
passed in as an argument then the C<yamlfile> attribute will be
examined. This method will fail if no file is specified through either
route. The C<directory> and C<yamlfile> attributes for the Job and the
C<basedir> attribute for the packages are not stored into the
meta-file. Only attributes which have the C<PkgForge::Serialise> trait
will be stored.


=item transfer($target_dir)

This will take a Job stored in one directory and copy it all to a new
target directory. The Job will be stored using the C<store_in_yamlfile>
method. Once the copy is complete it calls C<validate> to ensure that
the copied Job is correct. If anything fails then the target directory
will be erased. If the transfer succeeds then a new Job object will be
returned which represents the copy.

=item validate

This method validates the state of the Job. It requires that there are
Source packages, checks the SHA1 sum for each package and calls the
C<validate> method on each package. If anything fails then the method
will die with an appropriate message. If the method succeeds then a
boolean true value will be returned.

=item scrub($options)

This method will erase the directory associated with this build
job. Note that it also blows away the object since it no longer has
any physical meaning once the directory is gone. Internally this uses
the C<remove_tree> subroutine provided by L<PkgForge::Utils>. It is
possible, optionally, to pass in a reference to a hash of options to
control how the C<remove_tree> subroutine functions.

=item update_job_size

This will recalculate the job size by summing the sizes of all the
source packages. It is not normally necessary to do this manually as
it will be updated automatically whenever the packages list is
altered.

=back

=head1 DEPENDENCIES

This module is powered by L<Moose> and uses L<MooseX::Types>. It also
requires L<Data::UUID::Base64URLSafe> for UUID generation,
L<UNIVERSAL::require> for loading source package modules,
l<YAML::Syck> and L<Data::Structure::Util> for reading the build files
and converting them back into Job objects.

=head1 SEE ALSO

L<PkgForge>, L<PkgForge::Source>, L<PkgForge::Utils>
and L<PkgForge::Types>

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
