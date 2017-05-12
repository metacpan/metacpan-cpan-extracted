#!/usr/bin/perl

# $Id: 02_xml2hash.t,v 1.3 2002/09/08 04:11:54 andreychek Exp $

use strict;
use Test::More  tests => 2;
use lib ".";
use lib "lib";

my $xml = "<xml><can><you><hear><me><now>Good</now></me></hear></you></can></xml>";
use OpenThought::XML2Hash();

my $hash = OpenThought::XML2Hash::xml2hash( $xml );
ok ( $hash->{can}{you}{hear}{me}{now} eq "Good", "xml deserialization" );

my $hash2 = OpenThought::XML2Hash::xml2hash( $xml, "you" );
ok ( $hash2->{hear}{me}{now} eq "Good", "xml deserialization" );
