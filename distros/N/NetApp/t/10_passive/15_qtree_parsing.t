#!/usr/bin/env perl -w

use strict;
use warnings;

use lib 'blib/lib';
use lib 't/lib';
use NetApp::Test;

use Test::More qw( no_plan );
use Test::Exception;
use Data::Dumper;

use NetApp::Filer;
use NetApp::Qtree;

my @lines = split /\n/, <<__lines__;
volume_name              unix  enabled  normal    0    vfiler0
volume_name qtree_name   unix  enabled  normal    1    vfiler0
__lines__

foreach my $index ( 0 .. 1 ) {

    my $qtree = NetApp::Qtree->_parse_qtree_status_qtree( $lines[$index] );

    my $name =
        $index == 0 ? '/vol/volume_name' : '/vol/volume_name/qtree_name';

    ok( $qtree->{name} eq $name,
        "Parsed name correctly" );
    ok( $qtree->{security} eq 'unix',
        "Parsed security correctly" );
    ok( $qtree->{oplocks} == 1,
        "Parsed oplocks correctly" );
    ok( $qtree->{status} eq 'normal',
        "Parsed status correctly" );
    ok( $qtree->{id} =~ /^\d$/,
        "Parsed id correctly" );
    ok( $qtree->{vfiler} eq 'vfiler0',
        "Parsed vfiler correctly" );

}



