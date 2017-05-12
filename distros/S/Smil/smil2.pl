#!/usr/bin/perl -w

use lib '.';
use Smil;
use RN::RealText;

my $rt = new RN::RealText( height => 200, width => 200 );
$rt->addCode( "<b>Hey there</b>" );

my $smil2 = new Smil;
$smil2->addMedia( src => "foo.gif" );

my $s = new Smil;
$s->addInlinedMedia( src => $smil2 );
$s->addInlinedMedia( src => $rt );
$s->addMedia( src => "bar.gif", 
														href => "http://www.webiphany.com/", transition => "foo" );
$s->addTransition( id => "foo", type => "starWipe", horzRepeat => '3' );
print $s->getAsString . "\n";
