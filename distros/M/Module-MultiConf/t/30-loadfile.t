#!/usr/bin/perl
#
# $HeadURL: https://svn.oucs.ox.ac.uk/networks/src/debian/packages/libr/libmodule-multiconf-perl/trunk/t/30-loadfile.t $
# $LastChangedRevision: 1357 $
# $LastChangedDate: 2007-07-22 19:02:20 +0100 (Sun, 22 Jul 2007) $
# $LastChangedBy: oliver $
#

use strict;
use warnings FATAL => 'all';

use Test::More tests => 1;

use File::Temp 'tempfile';
use Data::Dumper;
$Data::Dumper::Terse = 1;

package ConfTest;
use Module::MultiConf;
package main;

sub mk_config {
    my $config = shift;
    my ( $fh, $path ) = tempfile( UNLINK => 1, SUFFIX => '.pl' );
    $fh->print( Dumper $config );
    $fh->close();
    return $path;
}

sub test_config {
    my ( $config, $msg ) = @_;
    my $path = mk_config($config);
    my $c = eval { ConfTest->new($path) };
    if ($@) {
        like( $@, qr/$msg/ );
    }
    else {
        isa_ok( $c, 'ConfTest' );
    }
    return $c;
}

my %config = (
    acl_path     => 'nuffink',
    server_class => 'pots',
    handlers     => {kettle => 'yellow'}
);

test_config( \%config, 'Loaded config must be a HASHREF of HASHREFs' );

