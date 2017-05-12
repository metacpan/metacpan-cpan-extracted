#!/usr/bin/perl

use Netscape::Bookmarks;
use HTTP::SimpleLinkChecker;

my $netscape = Netscape::Bookmarks->new( "../bookmark_files/Bookmarks.html" );

my $sub = sub {
	my $object = shift;
	my $level  = shift;
	
	if( $object->isa( 'Netscape::Bookmarks::Link' ) )
		{
		my $code = HTTP::SimpleLinkChecker::check_link( $object->href );
		print "\t" x $level . "[$code] " . $object->title . "\n";
		}
	else
		{
		print "\t" x $level . $object->title . "\n";
		}

	};

$netscape->recurse( $sub );
