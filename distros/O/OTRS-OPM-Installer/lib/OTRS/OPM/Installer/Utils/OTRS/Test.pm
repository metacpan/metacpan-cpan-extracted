package OTRS::OPM::Installer::Utils::OTRS::Test;
$OTRS::OPM::Installer::Utils::OTRS::Test::VERSION = '0.04';
# ABSTRACT: helper functions for Unittests

use strict;
use warnings;

use Moo::Role;
use File::Spec;
use File::Basename;

sub _find_path {
    my ($self) = @_;

    my @levels_up = ('..') x 5;
    my $dir       = File::Spec->catdir( dirname(__FILE__), @levels_up );
    my $testdir   = File::Spec->catdir( $dir, $ENV{OTRSOPMINSTALLERTEST} );

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

OTRS::OPM::Installer::Utils::OTRS::Test - helper functions for Unittests

=head1 VERSION

version 0.04

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
