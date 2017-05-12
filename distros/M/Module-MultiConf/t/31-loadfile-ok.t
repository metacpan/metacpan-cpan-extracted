#!/usr/bin/perl
#
# $HeadURL: https://svn.oucs.ox.ac.uk/networks/src/debian/packages/libr/libmodule-multiconf-perl/trunk/t/31-loadfile-ok.t $
# $LastChangedRevision: 1362 $
# $LastChangedDate: 2007-07-24 09:57:33 +0100 (Tue, 24 Jul 2007) $
# $LastChangedBy: oliver $
#

use strict;
use warnings FATAL => 'all';

use Test::More tests => 4;

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
        diag($@);
        like( $@, qr/$msg/ );
    }
    else {
        isa_ok( $c, 'ConfTest' );
    }
    return $c;
}

my $config = {
    config => {
        acl_path     => 'nuffink',
        server_class => 'pots',
        handlers     => {kettle => 'yellow'},
    },
};

#TODO: {
#    local $TODO = 'Bad tests (ab)using Config::Any';

    my $c = test_config( $config, 'should not die' );

    is( $c->config->{acl_path}, 'nuffink', 'config content 1' );
    is( $c->config->{server_class}, 'pots', 'config content 2' );
    is( $c->config->{handlers}->{kettle}, 'yellow', 'config content 3' );
#}
