use v5.14.0;
use warnings;

package OS::Package::Init;

# ABSTRACT: Initializes ospkg
our $VERSION = '0.2.7'; # VERSION

use base qw(Exporter);
use Path::Tiny;
use OS::Package::Config qw($OSPKG_CONFIG);
use OS::Package::Log qw($LOGGER);
use YAML::Any qw( DumpFile );

our @EXPORT = qw( init_ospkg );

sub init_ospkg {
    my ($opts) = @_;

    my @dirs = (
        $OSPKG_CONFIG->dir->base,    $OSPKG_CONFIG->dir->repository,
        $OSPKG_CONFIG->dir->configs, $OSPKG_CONFIG->dir->packages
    );

    foreach my $dir (@dirs) {

        if ( !path($dir)->exists ) {
            $LOGGER->info( sprintf 'creating directory: %s', $dir );
            path($dir)->mkpath;
        }
    }

    my $user_config = {
        config_dir => path($OSPKG_CONFIG->dir->configs)->stringify,
        pkg_dir    => path($OSPKG_CONFIG->dir->packages)->stringify,
    };

    DumpFile( path( $OSPKG_CONFIG->user_config ), $user_config );

    return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OS::Package::Init - Initializes ospkg

=head1 VERSION

version 0.2.7

=head1 METHODS

=head2 init_ospkg

Initializes ospkg.

=head1 AUTHOR

James F Wilkus <jfwilkus@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by James F Wilkus.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
