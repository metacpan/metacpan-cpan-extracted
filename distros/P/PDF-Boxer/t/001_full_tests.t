#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Data::Dumper;
use File::Slurp;

use lib 'lib';

use_ok('PDF::Boxer');
use_ok('PDF::Boxer::Doc');
use_ok('PDF::Boxer::SpecParser');

my @tests = qw! invoice !;
my @box_tests = qw! margin_top margin_right margin_bottom margin_left !;

my $test_dir = 't/full_tests';

my $parser = PDF::Boxer::SpecParser->new;

foreach my $test (@tests){
  my $pdfml = read_file( "$test_dir/$test.pdfml" );
  my $spec = $parser->parse($pdfml);
  my $boxer = PDF::Boxer->new( doc => { file => "full_test_$test.pdf" });
  $boxer->add_to_pdf($spec);
  $boxer->finish;
  test_boxer($test, $boxer);
}

sub test_boxer{
  my ($test, $boxer) = @_;

  my $data = read_file( "$test_dir/$test.data" );
  eval $data;

  my %boxes;
  foreach my $box ( values %{$boxer->box_register}){
    my $name = $box->name;
    foreach (@box_tests){
      $boxes{$name}{$_} = $box->$_;
    }
  }

  foreach my $box ( values %{$boxer->box_register}){
    my $name = $box->name;
    foreach my $unit ( @box_tests ){
      is( $boxes{$name}{$unit}, $data->{$name}{$unit}, "$name $unit");
    }
  }

}

done_testing();

