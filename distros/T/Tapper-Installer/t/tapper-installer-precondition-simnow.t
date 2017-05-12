#! /usr/bin/env perl

use strict;
use warnings;

use Test::More;
use File::Temp qw/tempdir/;

use YAML 'LoadFile';

BEGIN {
        use_ok('Tapper::Installer::Precondition::Simnow');
 }

my $tempdir = tempdir( CLEANUP => 1 );

my $config = {paths => {
                        base_dir    => $tempdir,
                        simnow_path => "/simnow/path",
                       },
              files => {
                        simnow_config => "$tempdir/config",
                        simnow_script => "family10_sles10_xen.simnow",
                       },
              hostname=> "uruk",
              mcp_port=> 12345,
              mcp_server=> "kupfer",
              prc_nfs_server=> "kupfer",
              report_api_port=> 12345,
              report_port=> 12345,
              report_server=> "kupfer",
              sync_port=> 1337,
              test_run=> 28372,
             };

my $simnow_installer = Tapper::Installer::Precondition::Simnow->new($config);
$simnow_installer->install();
my $loaded_config = LoadFile("$tempdir/config");

is($config->{files}{simnow_script}, "/simnow/path/scripts/family10_sles10_xen.simnow", 'Simnow script set');

done_testing();
