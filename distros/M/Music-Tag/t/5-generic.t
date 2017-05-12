#!/usr/bin/perl -w
use strict;

use Test::More tests => 37;
use 5.006;

BEGIN { use_ok('Music::Tag') }

my $tag1 = Music::Tag->new('t/fake.music',
                          { },
                          "Generic"
                         );

my $tag2 = Music::Tag->new('t/fake.music',
                          undef,
                          "Generic"
                         );

for my $tag ($tag1,$tag2) {
	ok($tag,          'Object created');
	ok(! $tag->plugin('Generic')->get_tag, 'get_tag called');
	ok(! $tag->plugin('Generic')->set_tag, 'set_tag called');
	ok ( $tag->artist('Beethoven'), 'artist set');
	ok ( $tag->album('GPL'), 'album set');
	ok ( $tag->plugin('Generic')->tagchange('artist', 'Beethoven'), 'tagchange 1'); 
	ok ( $tag->plugin('Generic')->tagchange('album' ), 'tagchange 2'); 
	is ( $tag->artist(), 'Beethoven', 'artist read');
	ok ( $tag->plugin('Generic')->simple_compare('A Simple Sentence', 'simple sentence'), 'Simple compare 1');
	ok ( $tag->plugin('Generic')->simple_compare('A Simple Sentence', 'simple sentence'), 'Simple compare 2');
	SKIP: { 
		skip "No Levenshtein Module", 2 unless ( $tag->options->{'LevenshteinXS'} || $tag->options->{'Levenshtein'}); 
		ok ( $tag->plugin('Generic')->simple_compare('A Simple Sentence', 'simple sentense',.9), 'Simple compare 3');
		ok ( $tag->plugin('Generic')->simple_compare('Notypo', 'No typos',.8), 'Simple compare 4');
	}
	ok ( ! $tag->plugin('Generic')->simple_compare('Notypo Simple Sentence', 'simple sentence are evel'), 'Simple compare fail');
	ok ( $tag->plugin('Generic')->changed(1), 'Tag changed');

	ok ( $tag->plugin('Generic')->options->{'hello'} = 'hello', 'set option');
	is ( $tag->plugin('Generic')->options->{'hello'}, 'hello', 'read opption');

	ok(! $tag->plugin('Generic')->strip_tag, 'strip_tag called');
	ok(! $tag->plugin('Generic')->close, 'close called');
}

