#!/usr/bin/perl

# $Id: 03_deserialize.t,v 1.3 2003/08/28 20:51:44 andreychek Exp $

use strict;
use Test::More  tests => 4;
use lib ".";
use lib "./t";
use OpenThoughtTests();

$OpenThought::Prefix = "./openthought";

my $o  = OpenThought->new( "", { OpenThoughtData => "openthought/" });

# The sample/test XML packet
my $openthought = "<OpenThought><fields><selectlist>linux</selectlist></fields><expr><run_mode>mode3</run_mode></expr><settings><session_id>96b8d09c1459c43465f5acc6f9c61787</session_id><need_script>1</need_script><runmode_param>run_mode</runmode_param><runmode>mode3</runmode></settings></OpenThought>";

my $hash = $o->deserialize( $openthought );
my $param_keys = join " ", sort keys %{ $hash };

ok ( $param_keys eq "expr fields run_mode session_id",
    "Deserialization -- Parameter Keys Test" );

ok ( $hash->{run_mode} eq "mode3",
    "Run Mode Deserialization" );

ok ( $hash->{fields}{selectlist} eq "linux",
    "Fields Deserialization" );

ok ( $hash->{session_id} eq "96b8d09c1459c43465f5acc6f9c61787",
    "Session ID Deserialization" );
