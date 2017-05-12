package PkgForge::ConfigFile; # -*-perl-*-
use strict;
use warnings;

# $Id: ConfigFile.pm.in 16519 2011-03-25 15:50:07Z squinney@INF.ED.AC.UK $
# $Source:$
# $Revision: 16519 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/PkgForge/PkgForge_1_4_8/lib/PkgForge/ConfigFile.pm.in $
# $Date: 2011-03-25 15:50:07 +0000 (Fri, 25 Mar 2011) $

our $VERSION = '1.4.8';

use English qw(-no_match_vars);
use YAML::Syck ();

use Moose::Role;
use Moose::Util::TypeConstraints;

my $extra_role = Moose::Meta::Role->initialize('MooseX::ConfigFromFile');
__PACKAGE__->meta->add_role($extra_role);

subtype 'ConfigList' => as 'ArrayRef[Str]';
coerce  'ConfigList' => from 'Str' => via { [$_] };

has 'configfile'=> (
    traits      => [ 'Array','Getopt' ],
    is          => 'ro',
    isa         => 'ConfigList',
    default     => sub { [] },
    coerce      => 1,
    predicate   => 'has_configfile',
    cmd_aliases => 'c',
    handles     => {
        'configlist' => 'elements',
    },
    documentation => 'The configuration file for this application',
);

sub new_with_config {
    my ( $class, @args ) = @_;

    my %opts;
    if ( scalar @args == 1 && ref $args[0] eq 'HASH' ) {
        %opts = %{$args[0]};
    } elsif ( @args % 2 == 0 ) {
        %opts = @args;
    }

    my $configfile = delete $opts{configfile};

    if ( !defined $configfile ) {
        my $cfmeta = $class->meta->find_attribute_by_name('configfile');
        $configfile = $cfmeta->default if $cfmeta->has_default;
    }

    if ( defined $configfile ) {
        %opts = ( %{$class->get_config_from_file($configfile)}, %opts );
    }

    $class->new(%opts);
}

sub get_config_from_file {
    my ( $class, $conf ) = @_;

    if ( !defined $conf ) { # should never happen but just in case...
        $conf = q{};
    } elsif ( ref $conf eq 'ARRAY' && scalar @{$conf} == 1 ) {
        $conf = $conf->[0];
    }

    # If the config file is a string and is prefixed with a plus (+)
    # it is an 'extra' file which should be appended to the default
    # list. Otherwise it is an override and the default is not
    # consulted.

    my $extra;
    if ( ref $conf eq q{} && $conf =~ m/^\+(.+)$/ ) {
        $extra = $1;
        my $attr = $class->meta->find_attribute_by_name('configfile');
        if ( $attr->has_default ) {
            $conf = $attr->default;
        } else {
            $conf = q{};
        }
    }

    if ( ref $conf eq 'CODE' ) {
        $conf = $conf->($class);
    }

    my @files_list;
    if ( ref $conf eq 'ARRAY' ) {
        @files_list = @{$conf};
    } elsif ( length $conf > 0 ) {
        @files_list = ($conf);
    }

    if ( defined $extra ) {
        push @files_list, $extra;
    }

    my %config;
    for my $file ( @files_list ) {
        if ( !-f $file ) {
            next; # just ignore
        }

        my $data = eval {
            # Allow true/false, yes/no for booleans
            local $YAML::Syck::ImplicitTyping = 1;

            YAML::Syck::LoadFile($file);
        };
        if (!defined $data || $EVAL_ERROR) {
            die "An error occurred whilst loading '$file': $EVAL_ERROR\n";
        }

        %config = ( %config, %{$data} );
    }

    $config{configfile} = [@files_list];

    return \%config;
}

no Moose::Role;

1;
__END__

=head1 NAME

     PkgForge::ConfigFile - A configuration file class for the LCFG Package Forge

=head1 VERSION

     This documentation refers to PkgForge::ConfigFile version 1.4.8

=head1 SYNOPSIS

     This is a Moose role and cannot be instantiated directly. Use it
     as shown below:

     package PkgForge::Foo;
     use Moose;

     with 'PkgForge::ConfigFile';

     # optionally, default the configfile:
     has '+configfile' => ( default => '/etc/foo.yaml' );

     ########
     ## A script that uses the class with a configfile
     ########

     my $obj = PkgForge::Foo->new_with_config(configfile => '/etc/bar.yaml',
                                              other_opt  => 'foo');

=head1 DESCRIPTION

This is a Moose role which can be applied to a class to give it the
ability to set values of attributes for new instances from
configuration files. The configuration file format must be YAML,
multiple files can be supplied which will be loaded in sequence.

=head1 ATTRIBUTES

=over

=item configfile

This attribute is provided by the base role
MooseX::ConfigFromFile. You can provide a default configfile pathname
like so:

         has '+configfile' => ( default => '/etc/myapp.yaml' );

You can also provide a list of files (wrapped in a sub to satisfy
Moose) as a default. Given a list of files the values of attributes
will come from the latest (right-most) file in which the attribute is
specified. The configuration format is YAML, in most cases all that is
required are simple key-value pairs separated with a colon, one
per-line, for example C<bucket: lcfg>, see L<YAML::Syck> for more
information.

=back

=head1 SUBROUTINES/METHODS

=head2 Class Methods

=over

=item get_config_from_file

This is used internally by either C<new_with_config> or the
C<new_with_options> method provided in the L<MooseX::Getopt> role.
This uses L<YAML::Syck> to parse the configuration files.

=item new_with_config

This is provided by the base role L<MooseX::ConfigFromFile>.  This
acts just like a regular C<new()>, but it also accepts an argument
C<configfile> to specify the configuration file from which to load
other attributes.  Explicit arguments to this method will override
anything loaded from the configfile. You may also pass in a string
which is the filename for the configuration file but with a plus-sign
(+) prefix. This file name will then be appended to the list which
comes from the default for the attribute (if any).

=back

=head1 DEPENDENCIES

This module is powered by L<Moose> and also uses
L<MooseX::ConfigFromFile> and L<YAML::Syck>

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
