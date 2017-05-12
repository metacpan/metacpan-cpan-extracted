#!/usr/bin/perl -w

use lib '.';
use Smil;

my $obj = new Smil( 'height' => 234, 'width' => 300,
		   'meta' => 
		   { "author" => "Chris Dawson",
		     "title" => "First PerlySMIL",
		     "copyright" => "2001 Chris Dawson"} );

# Set this to disable error checking
#$obj->disableErrorChecking;

my $region1 = "region1";
my $region2 = "region2";
my $region3 = "region3";

$obj->addRegion( "name" => $region1, "top" => 23, "left" => 45, 
		"height" => 200, "z-index" => 3, "width" => 250 );
$obj->addRegion(  "name" => $region2, "top" => 40, "left" => 85, 
		"height" => 200, "z-index" => 3, "width" => 250 );

$obj->addMedia( "type" => "audio",
	       "src" => "rtsp://realserver/g2audio.rm" );

$obj->startSequence();
$obj->addSwitchedMedia( "switch" => 'system-bitrate',
		       'medias' => 
		       [ { 'region' => $region1,
			   'switch-target' => 28000,
			   "src" => "rtsp://www.webiphany.com/video.rm" },
			{ 'region' => $region1,
			  "src" => "rtsp://www.yahoo.com/radio.rm" } ] );
			 # 'switch-target' => 36000 } ] );
$obj->addMedia( "region" => $region1, 
	       'href' => "http://www.webiphany.com",
	       "src" => "rtsp://realserver/g2video.rm" );
$obj->addComment( "This is a comment" );
$obj->addCode( "<RealAdInsert region=\"test\"/>" );
$obj->addMedia("region" => $region2, 
	       "anchors" => [ { 'href' => 'http://www.webiphany.com', 
				'coords' => '0,0,23,0' } ],
	       "src" => "rtsp://realserver/g2video.rm" );
$obj->endSequence();

$obj->getAsString();

print "Installed successfully.\n";
