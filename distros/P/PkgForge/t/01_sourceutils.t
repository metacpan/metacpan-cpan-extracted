#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 4;

use PkgForge::SourceUtils;
use File::Temp ();

my $test_package = 't/test-package-1-1.src.rpm';

my @handlers = PkgForge::SourceUtils::list_handlers();

ok( scalar(@handlers) >= 1, 'Find pkgforge source handlers' );

my $mods_ok = 1;
for my $handler (@handlers) {
    if ( $handler !~ m/^PkgForge::Source::(.+)$/ ) {
        $mods_ok = 0;
    }
}

ok( $mods_ok, 'Find pkgforge source handlers' );

SKIP: {
  eval { require RPM2 };

  skip 'RPM2 not installed', 1 if $@;

  my $module = PkgForge::SourceUtils::find_handler($test_package);
  is( $module, 'PkgForge::Source::SRPM', 'Find srpm handler module' );
}

# No handler for this so should return undef

my $testfile = File::Temp->new( SUFFIX => '.foo' );

my $module2 = PkgForge::SourceUtils::find_handler($testfile);
is( $module2, undef, 'Should not find any module' );
