#! /usr/bin/perl -w
use strict;
use 5.010;

use Regexp::Grammars;
use Data::Dumper 'Dumper';

my $grammar = qr{
    <Script>

    # THIS IS THE MAGIC BIT...
    <token: ws>
            ( \s+
            | ^ \# (file \s+ \S+, \s* line \s+ \d+ ) (?{ our $explicit_at = $^N })
            )*

    <rule: Script>
            <[Statement]>* \Z

    <rule: Statement>
            <Assignment> <where>
         |  <IfThenElse> <where>
         |  <Expression> <where>
         |  <error:>

    <token: where>
            <matchpos>
            <MATCH=(?{ our $explicit_at; $explicit_at || "line $MATCH{matchpos}" })>

    <rule: Assignment>
            <Variable>  [<]-  <Expression>

    <rule: Expression>
            <Product> \+ <Expression>
         |  <Product>

    <rule: Product>
            <Value>  [*]  <Product>
         |  <Value>

    <token: Value>
            \d+
         |  <Variable>

    <token: Variable>
            (?!if) [a-z]

    <rule: IfThenElse>
            if    <Condition>
            then  <Statement>
            else  <Statement>

    <rule: Condition>
            <Expression>  [<]  <Expression>

}xms;

do{ local $/; <DATA> } =~ $grammar
    or die "Bad script";

warn Dumper \%/

__DATA__

a <- 1

b <- 2

#file foo, line 27
if a<b then
    c <- 3
else
#file bar, line 100
    c
#file bar, line 200
    <- 99

b*c+a
