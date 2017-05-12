#!/usr/bin/perl

use strict;

use SWF::Parser;
use SWF::Element;

if (@ARGV==0) {
    print STDERR <<USAGE;
linkext.plx - Parse SWF file and show the URL referred by 'getURL'.
  perl linkext.plx swfname

USAGE

    exit(1);
} 
$Data::TemporaryBag::Threshold = 1000;

my $p=SWF::Parser->new('tag-callback' => \&tag);
$p->parse_file($ARGV[0]);

sub tag {
    my ($self, $tag, $length, $stream)=@_;
    my $t = SWF::Element::Tag->new(Tag=>$tag, Length=>$length);
    my ($tagname) = $t->tag_name;

    return unless
	          $tagname eq 'DoAction'      or
	          $tagname eq 'DoInitAction'  or
		  $tagname eq 'PlaceObject2'  or
		  $tagname eq 'DefineButton'  or
		  $tagname eq 'DefineButton2' or
		  $tagname eq 'DefineSprite';


    if ($tagname eq 'DefineSprite') {

# Tags in the sprite are not unpacked here.

	$t->shallow_unpack($stream);
	$t->TagStream->parse(callback => \&tag);
	return;


    } elsif ($tagname eq 'PlaceObject2') {

# Most of PlaceObject2 tags don't have ClipActions.

	$t->lookahead_Flags($stream);
	return unless $t->PlaceFlagHasClipActions;
    }

# unpack the tag and search actions.

    $t->unpack($stream);
    check_tag($t);
}

sub check_tag {
    my ($t, $stream) = @_;
    my ($tagname) = $t->tag_name;

    for ($tagname) {
	(/^Do(Init)?Action$/ or /^DefineButton$/) and do {
	    search_getURL($t->Actions);
	    last;
	};
	/^PlaceObject2$/ and do {
	    for my $ca (@{$t->ClipActions}) {
		search_getURL($ca->Actions);
	    }
	    last;
	};
	/^DefineButton2$/ and do {
	    for my $ba (@{$t->Actions}) {
		search_getURL($ba->Actions);
	    }
	    last;
	};
	/^DefineSprite$/ and do {
	    for my $tag (@{$t->ControlTags}) {
		check_tag($tag, $stream);
	    }
	    last;
	};
    }

}

sub search_getURL {
    my $actions = shift;

    for my $action (@$actions) {
	next unless $action->tag_name eq 'ActionGetURL';
	process_URL($action->UrlString->value);
    }
}

sub process_URL {
    print shift, "\n";
}


