use strict;
use warnings;
package Module::Version::Loaded;

our $VERSION = '0.000002';

use Module::Version 0.12 qw( get_version );
use Sub::Exporter -setup => {
    exports => [
        'diff_versioned_modules',
        'store_versioned_modules',
        'versioned_inc',
        'versioned_modules',
    ]
};

sub versioned_inc {
    my %versioned;
    foreach my $module ( keys %INC ) {
        my ( $version, undef ) = _module_version($module);
        $versioned{$module} = $version;
    }
    return %versioned;
}

sub versioned_modules {
    my %versioned;
    foreach my $file ( keys %INC ) {
        my ( $version, $module ) = _module_version($file);
        $versioned{$module} = $version;
    }
    return %versioned;
}

sub diff_versioned_modules {
    my $file1 = shift || '2 file names required';
    my $file2 = shift || '2 file names required';

    require Data::Difflet;
    require Storable;

    print Data::Difflet->new->compare(
        Storable::retrieve($file1),
        Storable::retrieve($file2)
    );
}

sub store_versioned_modules {
    my $file = shift || die 'file name required';
    my %versioned = versioned_modules();

    require Storable;
    Storable::nstore( \%versioned, $file );
}

sub _module_version {
    my $module = shift;
    $module =~ s{/}{::}g;
    $module =~ s{\.pm\z}{};
    return ( get_version($module) || undef, $module );
}
1;

=pod

=encoding UTF-8

=head1 NAME

Module::Version::Loaded - Get a versioned list of currently loaded modules

=head1 VERSION

version 0.000003

=head1 SYNOPSIS

    use Module::Version::Loaded qw( versioned_modules );

    my %modules = versioned_modules();
    # %modules contains: ( Foo::Bar => 0.01, Bar::Foo => 1.99, ... )

    # You can test this with a series of one-liners
    perl -MModule::Version::Loaded=store_versioned_modules -MTest::More -e "store_versioned_modules('test-more.txt')"
    perl -MModule::Version::Loaded=store_versioned_modules -MApp::Prove -e "store_versioned_modules('app-prove.txt')"
    perl -MModule::Version::Loaded=diff_versioned_modules -e "diff_versioned_modules('test-more.txt','app-prove.txt')"

=head1 DESCRIPTION

BETA BETA BETA

This module exists solely to give you a version of your %INC which includes the
versions of the modules you have loaded.  This is helpful when troubleshooting
different environments.  It makes it easier to see, at glance, which versions
of modules you have actually loaded.

=head1 FUNCTIONS

=head2 versioned_modules

Returns a C<Hash> of module versions, which is keyed on module name.

        use Module::Version::Loaded qw( versioned_modules );
        my %modules = versioned_modules();
        # contains:
        ...
        vars                         => 1.03,
        version                      => 0.9912,
        version::regex               => 0.9912,
        version::vxs                 => 0.9912,
        ...

=head2 versioned_inc

Returns a C<Hash> of module versions, which uses the same keys as %INC.  This
makes it easier to compare this data which %INC, since both Hashes will share
the same keys.

        use Module::Version::Loaded qw( versioned_inc );
        my %inc = versioned_inc();
        # contains:
        ...
        version.pm                    => 0.9912,
        version/regex.pm              => 0.9912,
        version/vxs.pm                => 0.9912,
        warnings.pm                   => 1.18,
        ...

        foreach my $key ( %INC ) {
            print "$key $INC{$key} $inc{$key}\n";
        }

=head2 store_versioned_modules( $file )

Serializes your versioned module list to an arbitrary file name which you must
provide.

=head2 diff_versioned_modules( $file1, $file2 )

Requires the name of two files, which have previously been serialized via
C<store_versioned_modules>.  Uses C<Data::Difflet> to print a comparison of
these data structures to STDOUT.

You can do this with a one-line to save time:

    perl -MModule::Version::Loaded=diff_versioned_modules -e "diff_versioned_modules('file1','file2')"

=head1 AUTHOR

Olaf Alders <olaf@wundercounter.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by MaxMind, Inc..

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

__END__
# ABSTRACT: Get a versioned list of currently loaded modules

