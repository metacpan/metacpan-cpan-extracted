#!/usr/bin/perl -w 

# $Id: 1.t,v 1.2 2005/11/29 12:09:10 mrodrigu Exp $

use strict;
use Data::Dumper;

my( @test_array, @cc_test, @test_refs, @test_tied, @test_warnings, @test_code, $test_nb);

BEGIN
  { @cc_test=( q{toTOTo    => to_TO_to},
               q{toTO      => to_TO},
               q{toTOT     => to_TOT},
               q{TOTto     => TO_tto},
               q{TOTOto    => TOT_oto},
               q{ToToToo   => to_to_too},
               q{to_TO_to  => to_TO_to},
               q{to_TO     => to_TO},
               q{a_b => a_b}, 
               q{ab_cd => ab_cd}, q{abCd => ab_cd}, q{AbCd => ab_cd}, q{ab_CD=>ab_CD}, q{abCD=>ab_CD}, q{ABCd=>AB_cd},
               q{abc_def => abc_def}, q{abcDef => abc_def}, q{AbcDef => abc_def},
               q{abc_DEF => abc_DEF}, q{abcDEF => abc_DEF}, q{AbcDEF => abc_DEF},
               q{abc_def_ghi => abc_def_ghi}, q{ABC_def_ghi => ABC_def_ghi}, q{abc_DEF_ghi => abc_DEF_ghi}, q{abc_def_GHI => abc_def_GHI},
               q{abcDefGhi => abc_def_ghi}, q{ABCDefGhi => ABC_def_ghi}, q{abcDEFGhi => abc_DEF_ghi}, q{abcDefGHI => abc_def_GHI},
               q{abDeGh => ab_de_gh}, q{ABDeGh => AB_de_gh}, q{abDEGh => ab_DE_gh}, q{abDeGH => ab_de_GH},
             );

    @test_array= (
    q{toto => foo              :                          :                          : 1 param, simple, lc},
    q{toto => Foo              : toto => Foo              :                          : 1 param, simple, lc},
    q{toto_tata => foo_bar     :                          : totoTata => foo_bar      : 1 param, 2words, lc},
    q{totoTata  => foo         : toto_tata => foo         :                          : 1 param, 2words, cc},
    q{toto => foo, tata => bar :                          :                          : 2 params, 1 word, lc},
    q{to_TO_to => foo          :                          : toTOTo => foo            : 1 param, accronym lc},
    q{to_TO => foo             :                          : toTO  => foo             : 1 param, accronym at end lc},
    q{toTOTo => foo            : to_TO_to => foo          :                          : 1 param, accronym cc},
    q{toTO => foo              : to_TO => foo             :                          : 1 param, accronym at end cc},
    q{toTOT => foo             : to_TOT => foo            :                          : 1 param, accronym at end cc},
    q{TOTto => foo             : TO_tto => foo            :                          : 1 param, accronym at end cc},
    q{TOTOto => foo            : TOT_oto => foo           :                          : 1 param, accronym at end cc},
    );

    @test_refs= (
    q{toto => foo : toto => foo : refs simple},
    q{AbCDE => ABCd, ABCd => abcd, ABC => 1 : ab_CDE => ABCd, AB_cd => abcd, ABC => 1 : refs long},
    );
 
    @test_tied= (
    q{toto => foo : toto => foo : tied simple},
    q{AbCDE => ABCd, ABCd => abcd, ABC => 1 : ab_CDE => ABCd, AB_cd => abcd, ABC => 1 : refs long},
    q{AbCdE => ABCdE, AbCd => abcd, AbC => 1 : ab_cd_e => ABCdE, ab_cd => abcd, ab_c => 1 : refs long2},
    );

    @test_code= (
    q{fooXMLBar   => fooXMLBar  : foo_XML_bar => fooXMLBar   : accronym and caps},
    q{foo_XML_bar => fooXMLBar  : foo_XML_bar => fooXMLBar   : already ok},
    q{foo_xml_bar => fooXMLBar  : foo_XML_bar => fooXMLBar   : ok but accronym in uc},
    q{fooXMLABar  => fooXMLABar : foo_xmla_bar => fooXMLABar : nearly an accronym caps},
    );
       

     $test_nb= 1 + (2 * @test_array) + @cc_test + ( 2 * @test_refs) + @test_tied + @test_warnings + @test_code;    
  }

use Test::More tests => $test_nb;
use Params::Style qw(:all);
ok(1);

foreach (@test_array)
  { my( $input, $lc_expected, $cc_expected, $name)= split /\s*:\s*/;

    $lc_expected||= $input; $cc_expected||= $input;

    my %input       = split /\s*(?:=>|,)\s*/, $input;
    my %lc_expected = split /\s*(?:=>|,)\s*/ => $lc_expected;
    my %cc_expected = split /\s*(?:=>|,)\s*/ => $cc_expected;

    my %lc    = perl_style_params( %input);
    my %cc    = javaStyleParams( %input);

    ok( eq_hash( \%lc, \%lc_expected), "lc $name") or diag( display( 'perl_style', \%input, \%lc, \%lc_expected) ); 
    ok( eq_hash( \%cc, \%cc_expected), "cc $name") or diag( display( 'javaStyle', \%input, \%cc, \%cc_expected) ); 
  }

foreach (@test_refs)
  { my( $input, $expected, $name)= split /\s*:\s*/;
    my @input       = split /\s*(?:=>|,)\s*/, $input;
    my @expected    = split /\s*(?:=>|,)\s*/ => $expected;

    my $arrayref_result= perl_style_params( \@input);
    ok( eq_array( $arrayref_result, \@expected), "array $name")
      or diag( display( 'perl_style array', \@input, $arrayref_result, \@expected) ); 
    
    my %input    = @input;
    my %expected = @expected;
    my $hashref_result= perl_style_params( \%input);
    ok( eq_hash( $hashref_result, \%expected), "hash $name")
      or diag( display( "perl_style hash", \%input, $hashref_result, \%expected) ); 
  }


foreach (@cc_test)
 { my( $in, $out)= split /\s*=>\s*/;
   my $result= Params::Style::perl_style( $in);
   ok( $result eq $out, $in) or diag( "$in => $result (should be $out)");
  }

foreach (@test_tied)
  { my( $input, $expected, $name)= split /\s*:\s*/;
    my @input       = split /\s*(?:=>|,)\s*/, $input;
    my %expected    = split /\s*(?:=>|,)\s*/ => $expected;

    my %result;
    tie %result, 'Params::Style', 'perl_style';
    %result= @input;
    ok( eq_hash( \%result, \%expected), "tied hash $name")
      or diag( display( 'perl_style tied hash', \@input, \%result, \%expected) ); 
    
  }

foreach (@test_code)
  { my( $input, $expected, $name)= split /\s*:\s*/;
    my @input       = split /\s*(?:=>|,)\s*/, $input;
    my %expected    = split /\s*(?:=>|,)\s*/ => $expected;

    my %result= replace_keys( \&code, @input);
    ok( eq_hash( \%result, \%expected), "code $name")
      or diag( display( 'code', \@input, \%result, \%expected) );
  }


exit;
 
sub code
  { my( $string)= @_;
    my %uc= map { $_ => 1 } qw( XML);
    my @parts;
    while( $string=~ s{^_?([a-z]+|[A-Z][a-z]+|[A-Z]+)(?=[A-Z_]|$)}{}) { push @parts, $1; }
    @parts= map { $uc{uc()} ? uc : lc } @parts;
    return join( _ => @parts);
  }
 

sub display
  { my( $func, $input, $result, $expected)= @_;
    my $hr= '-' x 40;
    return "$func\n".
           "Input:    ". trimmed_dump( $input). "\n".
           "Expected: ". trimmed_dump( $expected). "\n" .
           "Result:   ". trimmed_dump( $result). "\n$hr\n";
  }

sub trimmed_dump
  { my $var= shift;
    my @lines= split /\n/, Dumper( $var);
    shift @lines; pop @lines;
    @lines= map { s{^\s*}{}; $_} @lines;
    return join( ', ', @lines);
  }
