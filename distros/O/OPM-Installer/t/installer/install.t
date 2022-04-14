#!/usr/bin/env perl

use v5.10;

use strict;
use warnings;

use File::Basename;
use Test::More;

use lib dirname( __FILE__ ) . '/lib';

use MyManager;
use MyUtils;
use MyLogger;

use_ok 'OPM::Installer';

use OPM::Repository;

my $version = '6.0.1';
my $dir     = dirname( __FILE__ );
$dir        =~ s{installer\z}{file};
my $repo    = 'file://' . File::Spec->rel2abs( File::Spec->catdir( $dir, 'repo' ) );

my $installer = OPM::Installer->new(
    repositories => [ $repo ],
    manager      => MyManager->new, 
    version      => $version,
    utils_ts     => MyUtils->new,
    logger       => MyLogger->new,
    #verbose      => 1,
);

# package already installed
my $installed = 1;
eval {
    $installed = $installer->install( 'AccountedTimeInOverview' );
    1;
} or $installed = $@;
is $installed, 1, 'package already installed';

# package has to be installed
my $got_installed;
eval {
    $got_installed = $installer->install( 'ActionDynamicFieldSet' );
    1;
} or $got_installed = $@;
is $got_installed, 1, 'package got installed';

# package opm is invalid
my $error_msg;
eval {
    $installer->install('InvalidOPM');
    1;
} or $error_msg = $@; 

like $installer->logger->log, qr/Cannot parse .*?:/, 'OPM is invalid';

# no package (.opm) found
eval {
    $installer->install('NotFound');
    1;
} or $error_msg = $@; 

like $installer->logger->log, qr/Could not find a .opm file for NotFound \(framework version $version\)/, 'No opm found';

# install from URL
my $installed_from_url = 1;
eval {
    $installed_from_url = $installer->install( $repo . '/AccountedTimeInOverview-6.0.1.opm' );
    1;
} or $installed_from_url = $@;
is $installed_from_url, 1, 'installed from url';

done_testing();
