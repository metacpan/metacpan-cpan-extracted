#!/usr/bin/perl -w

use lib '.';
use Smil;

$s = new Smil;
$s->addMedia( src => "http://www.webiphany.com/images/bytravelers_thumb.jpg", inline => 1 );
print $s->getAsString;
