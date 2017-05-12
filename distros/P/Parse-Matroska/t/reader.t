#! /usr/bin/env perl

use 5.008;
use strict;
use warnings;
use Test::More tests => 29;
use FindBin;
use Data::Dumper;
use File::Spec::Functions qw{catfile};

BEGIN {
    use_ok("Parse::Matroska::Reader");
}

my $path = catfile($FindBin::Bin, qw{vectors dist.ini.mkv});

ok -e $path, "vectors/dist.ini.mkv is present";
ok my $r = Parse::Matroska::Reader->new($path), "Reader can be instantiated";

ok my $elem = $r->read_element, "Reads an EBML element correctly";
is $elem->{name}, "EBML", "Read EBML ID corresponds to the expected ID";
is $elem->{depth}, 0, "Read EBML Element depth is correct";

is $elem->{type}, 'sub', "EBML element has children";
ok my $chld = $elem->next_child, "Can read the first child of the element";

# this is to prevent exhaustively searching files
# specially bad on pipes
ok ! $elem->children_by_name("DocType"), "Can't find DocType element without populating";

$elem->populate_children;

ok my $other = $elem->next_child, "Can read through next_child after populate_children";
is $chld, $other, "The element read is exactly the same as the one read the first time";

ok $chld = $elem->children_by_name("DocType"), "Can find DocType element after populating";
is $chld->{name}, "DocType", "Element found is indeed DocType";
is $chld->get_value, "matroska", "DocType is 'matroska'";

ok $elem = $r->read_element, "Reads an EBML element after populate_children";
is $elem->{name}, "Segment", "The EBML element read is the expected one";

$elem->populate_children;

{ # Attachments tests
    # scalar children_by_name
    ok my $attachments = $elem->children_by_name("Attachments"),
        "Can locate Attachments using children_by_name";

    # recursive population
    $attachments->populate_children(1);

    # list children_by_name
    my @attach_files = $attachments->children_by_name("AttachedFile");

    ok scalar @attach_files, "Can find AttachedFile(s) inside Attachments";

    # scalar or list? :S
    ok $attach_files[0]->children_by_name("FileName"),
        "Can find children of first AttachedFile (recursive load works)";
    # scalar children_by_name
    is $attach_files[0]->children_by_name("FileName")->get_value, "dist.ini",
        "FileName contains the expected value";

    # scalar children_by_name
    ok my $file_data = $attach_files[0]->children_by_name("FileData"), "Can find FileData";
    ok $file_data->{type} eq 'binary', "FileData's type is binary";
    # tests delay-load
    ok my $data = $file_data->get_value, "Can read contents of binary blocks";
    is length($data), $file_data->{content_len}, "Length of the contents matches content_len";
}

{ # Info tests
    ok my $info = $elem->children_by_name("Info"), "Can locate first Info block";

    $info->populate_children;

    # scalar children_by_name
    ok defined(my $duration = $info->children_by_name("Duration")->get_value),
        "Can read the value of Duration";
    cmp_ok $duration, '==', 0, "Duration is 0";
}

$r->close;

my $test_str = "\x1a\x45\xdf\xa3\xa3";
SKIP: {
    skip q{Perls older than v5.14 don't like IO::File->new(\$scalar, '<:raw')}, 2 if $] < 5.014;

    ok $r->open(\$test_str), "Can open string readers";
    ok $elem = $r->read_element, "Can read a single element from string";
}
