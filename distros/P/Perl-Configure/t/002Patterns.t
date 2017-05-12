####################################################
# Tests for Perl::Configure::Questions patterns
####################################################
use strict;
use warnings;
use Test::More tests => 3;

use Perl::Configure::Questions;

####################################################
# Simple
####################################################
@Perl::Configure::Questions::QA = ();
my $questions = Perl::Configure::Questions->new();
$questions->add( "path-frobnicate",                 # token
                 "What's your frobnication path?",  # question
                 "/frob" );                         # sample answer
my($pattern) = $questions->patterns();
is($pattern, q{What\\'s\\ your\\ frobnication\\ path\\?}, #' calm down vim
   "pattern without ANY{}"); 

####################################################
# ANY{}
####################################################
@Perl::Configure::Questions::QA = ();
$questions = Perl::Configure::Questions->new();
$questions->add( "path-frobnicate",                 # token
                 "foo ANY{waa} bar",  # question
                 "/frob" );                         # sample answer
($pattern) = $questions->patterns();
is($pattern, q{foo\\ .*?\\ bar}, "pattern with ANY{}"); 

####################################################
# Double ANY{}
####################################################
@Perl::Configure::Questions::QA = ();
$questions = Perl::Configure::Questions->new();
$questions->add( "path-frobnicate",                 # token
                 "foo ANY{waa} bar ANY{woo} baz",  # question
                 "/frob" );                         # sample answer
($pattern) = $questions->patterns();
is($pattern, q{foo\\ .*?\\ bar\\ .*?\\ baz}, "pattern with double ANY{}"); 
