#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

BEGIN { plan skip_all => "This perl does not support infix isa" unless $^V ge v5.32; }

use String::Tagged;
use experimental qw(isa);

String::Tagged->new("cat") isa 'Foo';

my $begin = String::Tagged->new( "BEGIN" );
$begin->apply_tag( -1, 5, begin => 1 );

is( dies {
   my $str = String::Tagged->new( $begin );
}, undef, 'Prior use of infix isa does not upset method calls' );

done_testing;
