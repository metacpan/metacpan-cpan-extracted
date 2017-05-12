#!/usr/bin/perl

use Netscape::Bookmarks;

my $netscape = Netscape::Bookmarks->new( "../bookmark_files/Bookmarks.html" );

my $sub = sub {
	my $object = shift;
	my $level  = shift;
	
	print "Found object [" . $object . "] at level [$level]\n"
		if $ENV{NS_DEBUG};
	print "\t" x $level . $object->title . "\n";
	};

$netscape->recurse( $sub );
