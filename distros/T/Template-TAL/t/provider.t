#!perl
use warnings;
use strict;
use Data::Dumper;
use FindBin qw( $Bin );
use Test::XML;
use Test::More tests => 5;

use Template::TAL;
use Template::TAL::Provider::Disk;

ok( my $provider = Template::TAL::Provider::Disk->new->include_path($Bin),
  "created provider" );
ok( my $template = $provider->get_template("simple.tal"), "got template" );
my $expected = `cat $Bin/simple.tal`;

ok(!eval{ $provider->get_template("../Build.PL") }, "can't get template outside of 't' ($@)" );


# a sample custom provider
package MyProvider;
use base qw( Template::TAL::Provider );
sub get_template { return Template::TAL::Template->new->source('<foo/>') }
package main;

ok( my $tt = Template::TAL->new( provider => "MyProvider" ), "using custom provider" );
is_xml( $tt->process('bob'), "<foo/>", "is simple template" );
