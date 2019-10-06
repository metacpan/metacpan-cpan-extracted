#!/usr/bin/env perl
# vim:ts=4:shiftwidth=4:expandtab

use strict;
use warnings;

use RTF::Writer;
use RTF::Encode qw/ encode_rtf /;

my $rtf = RTF::Writer->new_to_handle(\*STDOUT);

$rtf->prolog("Escape examples");

print encode_rtf(q{These examples get decoded correctly be LibreOffice 6.0.7.3.});

print encode_rtf(q{Hello world, followed by new line
});

print encode_rtf("Snowman: ".chr(0x2603)."\n");
print encode_rtf("Snowman followed by letter: ".chr(0x2603)."Z\n");
print encode_rtf("Snowman followed by space then letter: ".chr(0x2603)." Z\n");

print encode_rtf("Smiling cat: ".chr(0x1f63b)."\n");
print encode_rtf("Smiling cat followed by letter: ".chr(0x1f63b)."Z\n");
print encode_rtf("Smiling cat followed by space then letter: ".chr(0x1f63b)." Z\n");
print encode_rtf("Text with\ttab\n");
