package OPM::Installer::Utils::Test;

# ABSTRACT: helper functions for Unittests

use strict;
use warnings;

our $VERSION = '1.0.1'; # VERSION

use Moo::Role;
use File::Spec;
use File::Basename;

sub _find_path {
    my ($self) = @_;

    my @levels_up = ('..') x 5;
    my $dir       = File::Spec->catdir( dirname(__FILE__), @levels_up );
    my $testdir   = File::Spec->catdir( $dir, $ENV{OPMINSTALLERTEST} );

    if ( !-d $testdir ) {
        $testdir = File::Spec->catdir( $dir, 3 );
    }

    return $testdir;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OPM::Installer::Utils::Test - helper functions for Unittests

=head1 VERSION

version 1.0.1

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
