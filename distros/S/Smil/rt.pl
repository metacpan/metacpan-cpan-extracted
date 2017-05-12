#!/usr/bin/perl -w

use lib '.';
use RN::RealText;

$rt = new RN::RealText( width => 200, height => 300, type => "scrollingnews" );
$rt->addCode( "<b>Hey there</b>" );
$rt->addCode( "<b>It is: " . `date`. "</b>" );
print $rt->getAsString();
