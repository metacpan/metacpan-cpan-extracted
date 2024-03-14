#!/usr/bin/env perl

use strict;
use warnings;

use CSS::Struct::Output::Raw;
use CPAN::Changes;
use Tags::HTML::CPAN::Changes;
use Tags::HTML::Page::Begin;
use Tags::HTML::Page::End;
use Tags::Output::Raw;
use Unicode::UTF8 qw(decode_utf8 encode_utf8);

my $css = CSS::Struct::Output::Raw->new;
my $tags = Tags::Output::Raw->new(
        'xml' => 1,
);

my $begin = Tags::HTML::Page::Begin->new(
        'author' => decode_utf8('Michal Josef Špaček'),
        'css' => $css,
        'generator' => 'EXAMPLE1',
        'lang' => {
                'title' => 'Hello world!',
        },
        'tags' => $tags,
);
my $end = Tags::HTML::Page::End->new(
        'tags' => $tags,
);
my $obj = Tags::HTML::CPAN::Changes->new(
        'css' => $css,
        'tags' => $tags,
);

# Example changes object.
my $changes = CPAN::Changes->new(
        'preamble' => 'Revision history for perl module Foo::Bar',
        'releases' => [
                CPAN::Changes::Release->new(
                        'date' => '2009-07-06',
                        'entries' => [
                                CPAN::Changes::Entry->new(
                                        'entries' => [
                                                'item #1',
                                        ],
                                ),
                        ],
                        'version' => 0.01,
                ),
        ],
);

# Init.
$obj->init($changes);

# Process CSS.
$obj->process_css;

# Process HTML.
$begin->process;
$obj->process;
$end->process;

# Print out.
print encode_utf8($tags->flush);

# Output:
# <!DOCTYPE html>
# <html lang="en"><head><meta http-equiv="Content-Type" content="text/html; charset=UTF-8" /><meta name="author" content="Michal Josef Špaček" /><meta name="generator" content="EXAMPLE1" /><meta name="viewport" content="width=device-width, initial-scale=1.0" /><title>Hello world!</title><style type="text/css">.changes{max-width:800px;margin:auto;background:#fff;padding:20px;border-radius:8px;box-shadow:0 2px 4px rgba(0, 0, 0, 0.1);}.changes .version{border-bottom:2px solid #eee;padding-bottom:20px;margin-bottom:20px;}.changes .version:last-child{border-bottom:none;}.changes .version h2,.changes .version h3{color:#007BFF;margin-top:0;}.changes .version-changes{list-style-type:none;padding-left:0;}.changes .version-change{background-color:#f8f9fa;margin:10px 0;padding:10px;border-left:4px solid #007BFF;border-radius:4px;}
# </style></head><body><div class="changes"><div class="version"><h2>0.01 - 2009-07-06</h2><ul class="version-changes"><li class="version-change">item #1</li></ul></div></div></body></html>