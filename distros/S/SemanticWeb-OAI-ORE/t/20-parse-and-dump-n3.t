#!/usr/bin/perl -T
#
# Test this module simple N3 example
#
# $Id: 20-parse-and-dump-n3.t,v 1.4 2010-12-06 14:44:02 simeon Exp $
use strict;
use warnings;

use English qw(-no_match_vars);
use Test::More;
use Getopt::Std;

my %opt;
(getopts('vh',\%opt)&&!$opt{h}) || die;

plan('tests'=>3);

use_ok( 'SemanticWeb::OAI::ORE::ReM' );
use_ok( 'SemanticWeb::OAI::ORE::N3' );

%ENV=();

my $file='t/examples/datamodel-overview/combined.n3';

diag("Using test file $file") if ($opt{v});
if (-r $file) {
  my $rem=SemanticWeb::OAI::ORE::ReM->new('debug'=>1);
  if ($rem->parsefile('n3',$file)) {
    diag("File $file parsed OK") if ($opt{v});
    my $test=$rem->model->as_n3;
    my $dump_file=$file.".dump";
    my $dump=read_file($dump_file);
    is($test,$dump,"N3 output from parsing $file matches stored dump $dump_file");
  } else {
    fail("Parse error with $file: errstr=".$rem->errstr()."\n");
  }
} else {
  fail("Configuration problem, can't find test file $file\n");
}


# Read $file and return as string, empty string on failure
#
sub read_file {
  my ($file)=@_;
  my $str='';
  if (open(my $fh,'<',$file)) {
    local $INPUT_RECORD_SEPARATOR=undef;
    $str=<$fh>;
  }
  return($str);
}
