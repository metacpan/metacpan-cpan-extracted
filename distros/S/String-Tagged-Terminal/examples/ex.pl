#!/usr/bin/perl

use v5.14;
use warnings;

use String::Tagged::Terminal;

my $st;

$st = String::Tagged::Terminal->new( "Basic colours: " );
$st->append_tagged( sprintf( " [%d] ", $_ ), fgindex => $_, bgindex => $_==0 ? 7 : undef ) for 0 .. 7;
$st->say_to_terminal;
$st = String::Tagged::Terminal->new( "               " );
$st->append_tagged( sprintf( " [%d] ", $_ ), bgindex => $_, fgindex => $_==7 ? 0 : undef ) for 0 .. 7;
$st->say_to_terminal;
print "\n";

$st = String::Tagged::Terminal->new( "Bold colours: " );
$st->append_tagged( sprintf( " [%d] ", $_ ), bold => 1, fgindex => $_, bgindex => $_==0 ? 7 : undef ) for 0 .. 7;
$st->say_to_terminal;
$st = String::Tagged::Terminal->new( "              " );
$st->append_tagged( sprintf( " [%d] ", $_ ), bold => 1, bgindex => $_, fgindex => $_==7 ? 0 : undef ) for 0 .. 7;
$st->say_to_terminal;
print "\n";

$st = String::Tagged::Terminal->new( "HI colours: " );
$st->append_tagged( sprintf( " [%d] ", $_ ), fgindex => $_ ) for 8 .. 15;
$st->say_to_terminal;
$st = String::Tagged::Terminal->new( "            " );
$st->append_tagged( sprintf( " [%d] ", $_ ), bgindex => $_ ) for 8 .. 15;
$st->say_to_terminal;
print "\n";

$st = String::Tagged::Terminal->new( "Attrs: " );
$st->append_tagged( $_, $_ => 1 )
   ->append( " " ) for qw( bold italic under strike blink reverse altfont );
$st->append_tagged( "super", baseline => "super" )
   ->append( "script ");
$st->append_tagged( "sub", baseline => "sub" )
   ->append( "script ");
$st->say_to_terminal;
print "\n";

print "256 colours:\n";
$st = String::Tagged::Terminal->new;

$st->append_tagged( "  ", bgindex => $_ ) for 0 .. 15;
$st .= "\n\n";

foreach my $b ( 0 .. 5 ) {
   $st->append_tagged( "  ", bgindex => 16 + $b*36 + $_ ) for 0 .. 35;
   $st .= "\n";
}
$st .= "\n";

$st->append_tagged( "  ", bgindex => 232 + $_ ) for 0 .. 23;
$st .= "\n";

$st->say_to_terminal;

$st = String::Tagged::Terminal->new;
$st->append( "Written by " )
   ->append_tagged( "String::Tagged::Terminal",
      altfont => 1,
      link    => "https://metacpan.org/pod/String::Tagged::Terminal" );
$st->say_to_terminal;
