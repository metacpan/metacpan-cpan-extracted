#!/usr/bin/perl -w

use lib '.';
use Smil;

my $s = new Smil;
$s->addMedia( src => "foo.gif", 'qt:bitrate' => 52000 );
$s->setQtAutoplay;
$s->setQtChapterMode( "clip" );
$s->useQtImmediateInstantiation;
$s->setQtNextPresentation( "foo.smi" );
$s->useQtTimeSlider;
$s->useQtExtensions;
print $s->getAsString;
