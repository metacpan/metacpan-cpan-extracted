#!/usr/bin/perl

use Netscape::Bookmarks;

my $netscape = Netscape::Bookmarks->new( "../bookmark_files/Bookmarks.html" );

my $sort = sub {
	my $object = shift;
	
	if( $object->isa( 'Netscape::Bookmarks::Category' ) )
		{
		$object->sort_elements();
		}

	};

my $print = sub {
	my $object = shift;
	my $level  = shift;
	
	print "Found object [" . $object . "] at level [$level]\n"
		if $ENV{NS_DEBUG};
	print "\t" x $level . $object->title . "\n";
	};

$netscape->recurse( $sort );

$netscape->recurse( $print );
