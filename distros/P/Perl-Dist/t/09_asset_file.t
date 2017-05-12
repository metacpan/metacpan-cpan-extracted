#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 5;
use File::Spec::Functions ':ALL';
use Perl::Dist::Asset::File;





#####################################################################
# Main Tests

my $file1 = Perl::Dist::Asset::File->new(
	share      => 'Perl-Dist default/perl-5.8.8/lib/CPAN/Config.pm.tt',
	install_to => 'CPAN/Config.pm',
);
isa_ok( $file1, 'Perl::Dist::Asset::File' );
is( $file1->share, 'Perl-Dist default/perl-5.8.8/lib/CPAN/Config.pm.tt', '->share ok' );
is( $file1->install_to, 'CPAN/Config.pm', '->install_to ok' );
like( $file1->url, qr/Config.pm.tt$/, '->url' );
is( $file1->file, 'Config.pm.tt', '->file ok' );
