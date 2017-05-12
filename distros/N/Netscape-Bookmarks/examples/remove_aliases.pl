#!/usr/bin/perl

use Netscape::Bookmarks;

my $netscape = Netscape::Bookmarks->new( "../bookmark_files/Bookmarks.html" );

my $remove = sub {
	my $object = shift;

	if( $object->isa( 'Netscape::Bookmarks::Category' ) )
		{
		foreach my $element ( $object->elements )
			{
			if( $element->isa( 'Netscape::Bookmarks::Alias' ) )
				{
				$object->remove_element( $element );
				}
			}
		}
	};

my $print = sub {
	my $object = shift;
	my $level  = shift;
	
	print "\t" x $level . $object->title . "\n";
	};

$netscape->recurse( $remove );

$netscape->recurse( $print );
