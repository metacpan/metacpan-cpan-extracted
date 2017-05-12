#!/usr/bin/perl -w

=head1 NAME

RegexpShellish.t - Test suite for RegexpShellish

=cut

use strict ;
use Test ;

use Regexp::Shellish qw( :all ) ;

my @samples = qw(
   ac
   AC
   abc
   ABC
   a/c
   A/C
   xaz
   xbz
   xcz
   q...t
) ;

my $re ;

sub k {
   my $expected ;
   ( $re, $expected ) = @_ ;
   $re = compile_shellish( $re, @_ > 2 ? pop : () ) ;
   @_ = ( join( ',', shellish_glob( $re, @samples ) ), $expected,  "/$re/" ) ;
   goto &ok ;
}


my @tests = (

sub {k( qr/a.*c/,     'ac,abc,a/c'          )},
sub {k( 'a.*c',       ''                    )},
sub {k( 'a?c',        'abc',                )},
sub {k( 'a\*c',       '',                   )},
sub {k( 'a\?c',       '',                   )},
sub {k( 'a\bc',       'abc',                )},
sub {k( 'a\(c',       '',                   )},
sub {k( 'a\)c',       '',                   )},
sub {k( 'a\{c',       '',                   )},
sub {k( 'a\}c',       '',                   )},

sub {k( 'a*c',        'ac,abc',                                        )},
sub {k( 'a*c',        'ac,abc',                { case_sensitive => 1 } )},
sub {k( 'a*c',        'ac,AC,abc,ABC',         { case_sensitive => 0 } )},

sub {k( 'a**c',       'ac,abc,a/c',                                    )},
sub {k( 'a**c',       'ac,abc,a/c',            { case_sensitive => 1 } )},
sub {k( 'a**c',       'ac,AC,abc,ABC,a/c,A/C', { case_sensitive => 0 } )},

sub {k( 'a**c',       'ac,abc,a/c',                               )},
sub {k( 'a**c',       'ac,abc,a/c',            { star_star => 1 } )},
sub {k( 'a**c',       'ac,abc',                { star_star => 0 } )},

sub {k( 'a...c',      'ac,abc,a/c',                                 )},
sub {k( 'a...c',      'ac,abc,a/c',            { dot_dot_dot => 1 } )},
sub {k( 'a...c',      '',                      { dot_dot_dot => 0 } )},
sub {k( 'q...t',      'q...t',                 { dot_dot_dot => 0 } )},

sub { 'abc' =~ compile_shellish( 'a(?)c'                 ) ; ok( $1, 'b' ) },
sub { 'abc' =~ compile_shellish( 'a(?)c', {parens => 1 } ) ; ok( $1, 'b' ) },
sub { ok( 'a(b)c' =~ compile_shellish( 'a(b)c', { parens => 0 } ) )},

sub {k( 'x{y}z',      '',                   )},
sub {k( 'x{a}z',      'xaz',                )},

sub {k( 'x{a,b}z',    'xaz,xbz',                           )},
sub {k( 'x{a,b}z',    'xaz,xbz',   { braces => 1 }         )},
sub {k( 'x{a,b}z',    '',          { braces => 0 }         )},
sub { ok( 'x{a}z' =~ compile_shellish( 'x{a}z', { braces => 0 } ) )},

sub { ok( 'abc' !~ compile_shellish( 'c' ) ) },
sub { ok( 'abc' =~ compile_shellish( 'c', { anchors => 0 } ) ) },
) ;

plan tests => scalar( @tests ) ;

$_->() for ( @tests ) ;

