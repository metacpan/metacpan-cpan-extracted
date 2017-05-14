#!/bin/perl

use 5.010 ;
use warnings;
use strict;

use Data::Dump 'pp';
use Data::Dumper;

use autodie qw(:all);


use TSQL::SplitStatement;
use TSQL::AST;

my $s = do { local $/ = undef; <> ;} ;

my $parser = TSQL::SplitStatement->new();

my @parsedInput = $parser->splitSQL($s);

my $parser2 = TSQL::AST->new();


#pp @parsedInput ;

my $parsedOutput= $parser2->parse(\@parsedInput);

#warn Dumper @parsedInput;
warn Dumper $parsedOutput;

#$parser2->parse($preProd[0],\@preProd);

#warn Dumper @preProd ;



__DATA__

