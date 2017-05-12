use v5.14.0;
use warnings;

package OS::Package::Factory;

# ABSTRACT: Initialize an OS::Package object.
our $VERSION = '0.2.7'; # VERSION

use Config;
use Env qw( $HOME );
use File::Basename;
use Module::Load;
use OS::Package;
use OS::Package::Application;
use OS::Package::Artifact;
use OS::Package::Config qw( $OSPKG_CONFIG );
use OS::Package::Log qw( $LOGGER );
use OS::Package::Maintainer;
use OS::Package::System;
use Path::Tiny;
use YAML::Any qw( LoadFile );

use base qw(Exporter);

our @EXPORT = qw( vivify );

local $YAML::UseCode  = 0 if !defined $YAML::UseCode;
local $YAML::LoadCode = 0 if !defined $YAML::LoadCode;

sub vivify {
    my ($arg_ref) = @_;
    my $name      = $arg_ref->{name};
    my $build_id  = $arg_ref->{build_id};

    my $cfg_file = sprintf '%s/%s.yml', path( $OSPKG_CONFIG->dir->configs ),
        lc($name);

    if ( !-f $cfg_file ) {
        $LOGGER->logcroak( sprintf 'cannot find configuration file %s for %s',
            $cfg_file, $name );
    }

    my $config = LoadFile($cfg_file);

    my $system = OS::Package::System->new;

    my $pkg;

    if ( defined $OSPKG_CONFIG->{plugin}{ $system->os }{ $system->version } )
    {
        my $plugin =
            $OSPKG_CONFIG->{plugin}{ $system->os }{ $system->version };

        load $plugin;

        my $app = OS::Package::Application->new(
            name    => $config->{name},
            version => $config->{version}
        );

        my $maintainer =
            OS::Package::Maintainer->new(
            author => $config->{maintainer}{author} );

        foreach my $method (qw( nickname email phone company )) {
            if ( defined $config->{maintainer}{$method} ) {
                $maintainer->$method( $config->{maintainer}{$method} );
            }
        }

        my $pkg_config = {
            name        => $config->{pkgname},
            version     => $config->{version},
            prefix      => $config->{prefix},
            description => $config->{description},
            maintainer  => $maintainer,
            application => $app,
        };

        if ( defined $build_id ) {
            $pkg_config->{build_id} = $build_id;
        }

        $pkg = $plugin->new($pkg_config);

    }
    else {
        $LOGGER->logcroak(
            sprintf 'cannot find plugin for %s %s',
            ucfirst( $system->os ),
            $system->version
        );
        return;
    }

    if ( defined $config->{build} ) {
        $pkg->install( $config->{build} );
    }

    if ( defined $config->{prune}{directories} ) {
        $pkg->prune_dirs( $config->{prune}{directories} );
    }

    if ( defined $config->{prune}{files} ) {
        $pkg->prune_files( $config->{prune}{files} );
    }

    my $artifact = OS::Package::Artifact->new;

    if ( defined $config->{url} ) {

        $artifact->distfile( basename( $config->{url} ) );
        $artifact->url( $config->{url} );
        $artifact->repository( path( $OSPKG_CONFIG->dir->repository ) );

        if ( defined $config->{md5} ) {
            $artifact->md5( $config->{md5} );
        }

        if ( defined $config->{sha1} ) {
            $artifact->sha1( $config->{sha1} );
        }

        my $savefile = sprintf( '%s/%s',
            path( $OSPKG_CONFIG->dir->repository ),
            basename( $config->{url} ) );

        $artifact->savefile($savefile);

    }
    elsif ( defined $config->{os}{ $pkg->system->os }{ $pkg->system->type } )
    {

        my $artifact_cfg =
            $config->{os}{ $pkg->system->os }{ $pkg->system->type };

        $artifact = OS::Package::Artifact->new(
            distfile   => basename( $artifact_cfg->{url} ),
            url        => $artifact_cfg->{url},
            repository => path( $OSPKG_CONFIG->dir->repository )
        );

        if ( defined $artifact_cfg->{md5} ) {
            $artifact->md5( $artifact_cfg->{md5} );
        }

        if ( defined $artifact_cfg->{sha1} ) {
            $artifact->sha1( $artifact_cfg->{sha1} );
        }

        $artifact->savefile(
            sprintf( '%s/%s',
                path( $OSPKG_CONFIG->dir->repository ),
                basename( $artifact_cfg->{url} ) )
        );

    }

    $pkg->artifact($artifact);

    return $pkg;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OS::Package::Factory - Initialize an OS::Package object.

=head1 VERSION

version 0.2.7

=head1 METHODS

=head2 vivify

Attempts to find the application configuration file and returns an OS::Package::Application object.

=head1 AUTHOR

James F Wilkus <jfwilkus@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by James F Wilkus.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
