
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  DISTNAME  => 'Spark-Form',
  NAME      => 'Spark::Form',
  AUTHOR    => 'James\ Laver\ L\<http\:\/\/jameslaver\.com\>',
  ABSTRACT  => 'A\ simple\ yet\ powerful\ forms\ validation\ system\ that\ promotes\ reuse\.',
  VERSION   => '0.2102',
  EXE_FILES => [ qw() ],
  (eval { ExtUtils::MakeMaker->VERSION(6.31) } ? (LICENSE => 'perl') : ()),
  PREREQ_PM    => {
    "Module::Pluggable" => '0',
    "MooseX::LazyRequire" => '0.04',
    "Test::More" => '0',
    "List::Util" => '0',
    "Data::Couplet" => '0.02004312',
    "MooseX::AttributeHelpers" => '0.21',
    "List::MoreUtils" => '0',
    "Moose" => '0.89',
    "HTML::Tiny" => '0',
  },
);
