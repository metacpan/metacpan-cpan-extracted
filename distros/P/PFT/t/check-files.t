#!/usr/bin/perl -w

use v5.16;

use strict;
use warnings;
use utf8;

use feature qw/say/;

use PFT::Content::Entry;
use PFT::Header;

use Test::More;
use File::Temp;
use File::Spec;

my $dir = File::Temp->newdir();

my $page = PFT::Content::Entry->new({
    tree => undef,
    path => File::Spec->catfile($dir, 'foo'),
});

is($page->name, 'foo', 'Default name');

is($page->header, undef, 'Empty file has no header');
is($@, '', 'But also no error');

do {
    my($h, $text) = $page->read();
    is($h, undef, 'Read goes undef 1');
    is($text, undef, 'Read goes undef 2');
};

do {
    my $fh = $page->open('w');
    print $fh 'Hello';
};

is(eval{ $page->header }, undef, 'Arbitrary text has no header');
isnt($@, undef, 'Error instead');
#diag('Error was: ', $@);

eval {
    my($h, $fh) = $page->read();
};
isnt($@, undef, 'Error also if reading');

# Header placement (on unlinked file)
my $header = PFT::Header->new(title => 'foo');

do {
    $page->unlink;
    $page->set_header($header);

    my $h2 = PFT::Content::Entry->new({
        tree => undef,
        path => $page->path
    })->header;

    is_deeply($header, $h2, 'Placing header');
};

# Header replacement (on file having header)
do {
    my $fh = $page->open('a');
    print $fh 'Some random text';
    close $fh;
};
do {
    my $h_alt = PFT::Header->new(title => 'bar');
    $page->set_header($h_alt);

    my($h_got, $fh) = $page->read();

    my @lines = <$fh>;
    is(scalar @lines, 1, 'One line read');
    is($lines[0], 'Some random text', 'Line is correct');
    is_deeply($h_got, $h_alt, 'Header was placed');
};

done_testing()
