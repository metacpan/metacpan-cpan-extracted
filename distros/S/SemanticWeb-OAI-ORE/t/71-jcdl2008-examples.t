#!/usr/bin/perl -T
#
# Tests to deal with example from JCDL2008 paper
#
##### FIXME - Put Atom code back when moved to current spec
#
# $Id: 71-jcdl2008-examples.t,v 1.12 2010-12-06 14:44:02 simeon Exp $
use strict;
use warnings;

use lib qw(t/lib);
use English qw(-no_match_vars);
use Diff qw(diff);
use Test::More;
use Getopt::Std;

plan('tests'=>5);

use_ok( 'SemanticWeb::OAI::ORE::ReM' );
#use_ok( 'SemanticWeb::OAI::ORE::Atom' );
use SemanticWeb::OAI::ORE::Constant qw(:all);

my $file_base='t/examples/jcdl2008_paper/example';

my $file="$file_base.n3";
if (not -r $file) {
  BAIL_OUT("Configuration problem, can't find test file $file\n");
}
my $rem=SemanticWeb::OAI::ORE::ReM->new('debug'=>1);
diag("Parsing N3 from $file") if ($ENV{TEST_VERBOSE});

ok($rem->parsefile('n3',$file), "File parsed OK");
ok($rem->is_valid, "ReM is valid");
if (not $rem->is_valid) {
  BAIL_OUT("Parse error with $file: errstr=".$rem->errstr()."\n");
}

# Check place to write test dump file, other tests will fail 
# if this one does...
my $test_tmp='t/tmp';
ok(-d $test_tmp and -w $test_tmp,"Test tmp dir ($test_tmp) exists/writable");
my $test_file="$test_tmp/21-parse-n3-and-dump-rdf.rdf";
my $tmp_base="$test_tmp/71-jcdl2008-examples";

# Dump as N3 and check against stored dump file
my $n3a=$rem->model->as_n3;
my $new_n3_dump="$tmp_base.n3a";
dump_str_to_file($n3a,$new_n3_dump,'N3->ReM->N3');
my $n3_dump_file=$file.".dump";
my $n3_dump=read_file($n3_dump_file);
check_and_diff($n3a,$n3_dump,"Check N3 dump against test copy: $new_n3_dump $n3_dump_file");

##Atom has changed radicall since initial version in 2008
##Code below needs fixing 2010-05-05
exit;


# Dump as Atom and check against stored Atom dump
my $atom1=$rem->serialize('atom');
my $uri_rem=$rem->uri();
my $new_atom_dump="$tmp_base.atom1";
dump_str_to_file($atom1,$new_atom_dump,'N3->ReM->Atom');
my $atom_dump_file=$file_base.".atom.dump";
my $atom_dump=read_file($atom_dump_file);
check_and_diff($atom1,$atom_dump,"Check Atom dump against test copy: $new_atom_dump $atom_dump_file");

# Parse again
my $rem1=SemanticWeb::OAI::ORE::ReM->new('debug'=>1,'die_level'=>RECKLESS);
print "Parsing Atom...\n";
if (not $rem1->parse('atom',$atom1,$uri_rem)) {
  fail("Parse error with: ".$rem1->errstr);
} else {
  # Now have $rem1, serialize and reparse
  diag("PARSE ERRORS:\n".$rem1->errstr."----\n") if ($rem1->errstr);

  # Dump as N3 and check 
  my $n3b=$rem1->model->as_n3;
  dump_str_to_file($n3b,"$tmp_base.n3b",'N3->ReM->Atom->ReM->N3');
  check_and_diff($n3b,$n3_dump,"N3 output from parsing atom matches $n3_dump_file");

  my $atom2=$rem1->serialize('atom');
  dump_str_to_file($atom2,"$tmp_base.atom2",'N3->ReM->Atom->ReM->Atom');
  check_and_diff($atom2,$atom_dump,"Atom output matches $atom_dump_file");

  my $rem2=SemanticWeb::OAI::ORE::ReM->new('debug'=>1,'die_level'=>RECKLESS);
  if (not $rem2->parse('atom',$atom2,$uri_rem)) {
    fail("Parse error: ".$rem2->errstr);
  } else {
    diag("PARSE ERRORS:\n".$rem2->errstr."----\n") if ($rem2->errstr);
    my $n3c=$rem2->model->as_n3;
    dump_str_to_file($n3c,"$tmp_base.n3c",'N3->ReM->Atom->ReM->Atom->N3');
    check_and_diff($n3c,$n3_dump,"N3 output from reparsing atom matches $n3_dump_file");
  }
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


sub check_and_diff {
  my ($a,$b,$msg)=@_;
  if ($a eq $b) {
    pass($msg);
  } else {
    my @a=split("\n",$a);
    my @b=split("\n",$b);
    my $d=diff(\@a,\@b);
    my $got="\n";
    my $expected="\n";
    my $hn=0;
    foreach my $hunk (@$d) {
      $hn++;
      #$str.="[hunk $hn]\n";
      foreach my $chunk (@$hunk) {
        my ($type,$pos,$txt)=@$chunk;
        if ($type=~/^\-/) {
          $got.="$type$pos |$txt|\n";
        } else {
          $expected.="$type$pos |$txt|\n";
        }
      }
    }
    is($got,$expected,$msg." (diff shown)");
  }
}


sub dump_str_to_file {
  my ($str,$file,$msg)=@_;
  if (open(my $fh,'>',$file)) {
    print {$fh} $str;
    close($fh);
    diag("Dumped $msg to $file") if ($ENV{TEST_VERBOSE});
  } else {
    die "Can't write $msg to $file: $!";
  }
}
