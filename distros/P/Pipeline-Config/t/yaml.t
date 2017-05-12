#!/usr/bin/perl

##
## Tests for Pipeline::Config::YAML
##

use blib;
use lib 't/lib';
use strict;
use warnings;

use Test::More qw( no_plan => 1 );

use Error qw( :try );
use Pipeline;

BEGIN { use_ok("Pipeline::Config") }

my $parser = new Pipeline::Config;
ok( $parser, 'new' ) || die "cannot continue\n";

is( $parser->debug(0), $parser, 'debug(set)' );
is( $parser->debug, 0,          'debug(get)' );

{
    my $pipe;
    try { $pipe = $parser->load( 't/conf/config.yaml' ); }
    catch Error with { fail( 'load config.yaml: ' . shift); };

    if (isa_ok( $pipe, 'Pipeline', 'load yaml config' )) {
	my $subpipe = $pipe->segments->[-1];
	if (isa_ok( $subpipe, 'Pipeline', 'subpipe' )) {
	    my $seg = $subpipe->segments->[-1];
	    if (isa_ok( $seg, 'Test::Segment', 'last seg' )) {
		is( $seg->{foo}, 'bar', 'foo/bar set' );
	    }
	}
	my $cleanups = $pipe->cleanups;
	if (isa_ok( $cleanups, 'Pipeline', 'cleanups' )) {
	    my $seg = $cleanups->segments->[0];
	    if (isa_ok( $seg, 'Test::Segment', 'cleanups seg' )) {
		is( $seg->{foo}, 'baz', 'foo/baz set' );
	    }
	}
    }
    #use Data::Dumper;
    #print Dumper( $pipe );
}

{
    my $e;
    try { $parser->load( 't/conf/non-existent.yaml' ); }
    catch Error with { $e = shift; };
    isa_ok( $e, 'Error', 'load non-existent.yaml' );
  TODO: {
    local $TODO = 'implement this';
    isa_ok( $e, 'Pipeline::Config::LoadError', 'load non-existent.yaml' );
    }
}

{
    my $e;
    try { $parser->load( 't/conf/bad-classname.yaml' ); }
    catch Error with { $e = shift; };
    isa_ok( $e, 'Pipeline::Config::LoadError', 'load config w/bad class name' );
    like  ( $e, qr/Error loading class/,       'error loading class' );
}

{
    my $pipe;
    try {
	 $pipe = $parser->load( 't/conf/config-abbrev.yml' );
    }
    catch Error with { fail( 'load config-abbrev.yml: ' . shift); };

    if (isa_ok( $pipe, 'Pipeline', 'load abbreviated yaml config' )) {
	my $subpipe = $pipe->segments->[-1];
	if (isa_ok( $subpipe, 'Pipeline', 'subpipe' )) {
	    my $seg = $subpipe->segments->[-1];
	    if (isa_ok( $seg, 'Test::Segment', 'last seg' )) {
		is( $seg->{foo}, 'bar', 'foo/bar set' );
	    }
	}
    }
}

package Test::Segment;
use base qw( Pipeline::Segment );
sub foo {
    my $self     = shift;
    $self->{foo} = shift;
}
