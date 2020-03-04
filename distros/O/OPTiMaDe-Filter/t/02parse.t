#!/usr/bin/perl

use strict;
use warnings;
use Data::Compare;
use Data::Dumper;
use File::Spec::Functions;
use OPTiMaDe::Filter::Parser;
use Test::More;

$Data::Dumper::Sortkeys = 1;

my $input_dir  = catdir( 'tests', 'cases' );
my $output_dir = catdir( 'tests', 'outputs' );

opendir my $dir, $input_dir || die "Cannot open directory: $!";
my @inputs = sort grep { /\.inp$/ } readdir $dir;
closedir $dir;

my $ntests = @inputs;
plan tests => $ntests;

for my $case (@inputs) {
    $case =~ /([^\/\\]+)\.inp$/;
    my $input_file   = catdir( $input_dir,  $case );
    my $options_file = catdir( $input_dir,  "$1.opt" );
    my $output_file  = catdir( $output_dir, "$1.out" );

    my $options = {};
    if( -e $options_file ) {
        open( my $inp, '<', $options_file );
        while( <$inp> ) {
            chomp;
            $options->{$_} = 1;
        }
        close $inp;
    }

    $OPTiMaDe::Filter::Parser::allow_LIKE_operator =
        defined $options->{allow_LIKE_operator};    

    my( $tree, $output );
    my $parser = new OPTiMaDe::Filter::Parser;
    eval {
        $tree = $parser->Run( $input_file );
    };
    $output = $@ if $@;

    if( $tree ) {
        $output .= Dumper( $tree ) .
                   "== Filter ==\n" .
                   $tree->to_filter . "\n" .
                   "== SQL ==\n";
    }

    if( $tree ) {
        eval {
            if( $options->{use_placeholders} ) {
                my( $sql, $values ) = $tree->to_SQL( { placeholder => '?' } );
                $output .= "$sql\n" .
                           "=== Values ===\n" .
                           Dumper $values;
            } else {
                $output .= $tree->to_SQL . "\n";
            }
        };
        $output = $@ . $output if $@;
    }

    open( my $out, $output_file );
    my $expected = join '', <$out>;
    close $out;
    is( $output, $expected, $case );

    next unless $tree;

    my $filter = $tree->to_filter;
    $parser = new OPTiMaDe::Filter::Parser;
    my $tree_now = $parser->parse_string( $filter );
    Compare( $tree, $tree_now ) || print "Roundtrip NOT passed\n";
}
