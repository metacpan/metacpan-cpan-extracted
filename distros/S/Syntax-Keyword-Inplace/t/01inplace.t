#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Syntax::Keyword::Inplace;

# uc
{
   my $str = "hello";
   inplace uc $str;
   is( $str, "HELLO", 'inplace uc on lexvar' );
}

# func
{
   sub wrap { return "<$_[0]>" }

   my $var = "abc";
   inplace wrap $var;
   is( $var, "<abc>", 'inplace 1arg function call on lexvar' );
}

# EXPR side-effects happen only once
{
   my $count = 0;
   my @arr = ( "x" );
   inplace uc $arr[$count++];
   is( $arr[0], "X", 'inplace uc on aelem with side-effect' );
   is( $count, 1, 'side-effect happened only once' );
}

{
   no Syntax::Keyword::Inplace;

   sub inplace { return "normal function" }

   is( inplace, "normal function", 'inplace() parses as a normal function call' );
}

done_testing;
