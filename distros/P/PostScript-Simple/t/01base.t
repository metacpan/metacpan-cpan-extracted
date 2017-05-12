#!/usr/bin/perl -w
use strict;
use lib qw(./lib ../lib t/lib);
use Test::Simple tests => 10;
#use Data::Dumper;
use PostScript::Simple;

ok( $PostScript::Simple::VERSION );	# module loads
my $p = new PostScript::Simple(papersize => "A4",
                                colour => 1,);
ok( $p ); # object creation
ok( $p->{xsize} == 595.27559 );
ok( $p->{ysize} == 841.88976 );
ok( $p->{colour} == 1 );
ok( $p->{eps} == 1 );
ok( $p->{page} == 1 );
ok( $p->{landscape} == 0 );
ok( $p->{units} eq 'bp' );
ok( $p->{papersize} eq 'A4' );

# basic test for default values

#print Dumper $p;
