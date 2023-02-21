#!/usr/bin/perl

use v5.14;
use warnings;

use Convert::Color;
use Getopt::Long;
use String::Tagged;

GetOptions(
   'f|format=s' => \my $FORMAT,
   'c|class=s'  => \my $CLASS,
) or exit 1;

my $st = String::Tagged->new;

my %COLORS = map { $_ => Convert::Color->new( "vga:$_" ) } qw( red blue green yellow black white );

$st->append( "Foregrounds:\n" );
$st->append( "  " ), $st->append_tagged( $_, fg => $COLORS{$_} )
   for qw( red blue green yellow black white );
$st->append( "\n" );

$st->append( "Backgrounds:\n" );
$st->append( "  " ), $st->append_tagged( $_, bg => $COLORS{$_} )
   for qw( red blue green yellow black white );
$st->append( "\n" );

$st->append( "Mixed:\n" );
$st->append( "  " ), $st->append_tagged( "black-on-white", fg => $COLORS{black}, bg => $COLORS{white} );
$st->append( "  " ), $st->append_tagged( "white-on-black", fg => $COLORS{white}, bg => $COLORS{black} );
$st->append( "\n" );

$st->append( "Attributes:\n" );
$st->append( "  " ), $st->append_tagged( $_, $_ => 1 )
   for qw( bold under italic strike blink monospace reverse  );
$st->append( "  " ), $st->append_tagged( "sizepos=$_", sizepos => $_ )
   for qw( sub super );
$st->append( "\n" );

defined $FORMAT or defined $CLASS or
   $FORMAT = "HTML";

$CLASS //= "String::Tagged::$FORMAT";
require "$CLASS.pm" =~ s{::}{/}gr;

# TODO: match/case on class name? ;)
if( $CLASS eq "String::Tagged::HTML" ) {
   say $CLASS->new_from_formatting( $st, use_style => 1 )
      ->as_html;
}
if( $CLASS =~ m/^String::Tagged::Markdown(::.*|$)/ ) {
   say $CLASS->new_from_formatting( $st )
      ->build_markdown;
}
if( $CLASS eq "String::Tagged::Terminal" ) {
   $CLASS->new_from_formatting( $st )
      ->say_to_terminal;
}
