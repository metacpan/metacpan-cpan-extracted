#! perl
#
# Testing JSON iterator.

use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);
use Class::Load qw(try_load_class);

try_load_class('JSON')
    or plan skip_all => "No JSON module.";

require Template::Flute::Iterator::JSON;

plan tests => 6;

my $json = q{[
{"sku": "orange", "image": "orange.jpg"},
{"sku": "pomelo", "image": "pomelo.jpg"}
]};

subtest "JSON string as is" => sub {
    my $json_iter = Template::Flute::Iterator::JSON->new($json);

    isa_ok($json_iter, 'Template::Flute::Iterator');

    ok($json_iter->count == 2);

    isa_ok($json_iter->next, 'HASH');
};

subtest "JSON string as scalar" => sub {
    my $json_iter = Template::Flute::Iterator::JSON->new(\$json);
    isa_ok($json_iter, 'Template::Flute::Iterator');
    ok($json_iter->count == 2);
    isa_ok($json_iter->next, 'HASH');
};

subtest "Read JSON from file" => sub {
    plan tests => 5;

    my ($json_fh, $json_file) = tempfile;
    print $json_fh $json, "\n";
    close $json_fh;
    my $json_file_iter = Template::Flute::Iterator::JSON->new(file => $json_file);

    isa_ok $json_file_iter, 'Template::Flute::Iterator';
    is $json_file_iter->count, 2, "Iterator count is correct";
    isa_ok $json_file_iter->next, 'HASH', "Next item is a hash";

    {
        eval {Template::Flute::Iterator::JSON->new(file => "non-existent-file") };
        like $@, qr/failed to open JSON file non-existent-file/,
            "Fails with expected message when file doesn't exist";
    }

    {
        eval {Template::Flute::Iterator::JSON->new() };
        like $@, qr/Missing JSON file/, "Fails without JSON string, ref or file";
    }

};

subtest "Read UTF8 JSON from file" => sub {
    plan tests => 5;

    my $json = q{[
    {"sku": "Größenmaßstäbe", "images": ["mètre.jpg", "el_módulo.png"]},
    {"sku": "Fußgängerübergänge", "images": ["surépaisseur.jpg", "transición.png"]}
    ]};
    my ($json_fh, $json_file) = tempfile;
    binmode( $json_fh, ":encoding(UTF-8)" );
    print $json_fh $json, "\n";
    close $json_fh;
    my $json_file_iter = Template::Flute::Iterator::JSON->new(file => $json_file);
    is $json_file_iter->count, 2, "Iterator count is correct";
    isa_ok $json_file_iter->next, 'HASH', "Next item is a hash";
    isa_ok $json_file_iter->next, 'HASH', "The following item is also a hash";
    is $json_file_iter->next, undef, "Iterating past the end gives undef";
    $json_file_iter->reset;
    isa_ok $json_file_iter->next, 'HASH', "First item is a hash after reset";
};

subtest "Selector option" => sub {
    plan tests => 8;

    my $json = q{[
    {"sku": "orange", "images": ["orange.jpg", "orange.png"]},
    {"sku": "pomelo", "images": ["pomelo.jpg", "pomelo.png"]}
    ]};

    my ($json_fh, $json_file) = tempfile;
    print $json_fh $json, "\n";
    close $json_fh;

    my $json_file_iter = Template::Flute::Iterator::JSON->new(
        file => $json_file, selector => 'unknown');
    isa_ok $json_file_iter, 'Template::Flute::Iterator';
    is $json_file_iter->count, 0, "Unknown selector seeds iterator with empty list";

    $json_file_iter = Template::Flute::Iterator::JSON->new(
        file => $json_file, selector => 'sku', children => 'unknown');
    isa_ok $json_file_iter, 'Template::Flute::Iterator';
    is $json_file_iter->count, 0, "Unknown children seeds iterator with empty list";

    my %selector = ('sku' => "unknown");
    $json_file_iter = Template::Flute::Iterator::JSON->new(
        file => $json_file, selector => \%selector, children => 'images');
    isa_ok $json_file_iter, 'Template::Flute::Iterator';
    is $json_file_iter->count, undef,
        "Unknown selector value returns undef";

    %selector = ('sku' => "orange");
    $json_file_iter = Template::Flute::Iterator::JSON->new(
        file => $json_file, selector => \%selector, children => 'images');
    isa_ok $json_file_iter, 'Template::Flute::Iterator';
    is $json_file_iter->count, 2,
        "Known children seeds iterator number of child elements in slected element";
};

subtest "'*' selector option" => sub {
    plan tests => 4;

    my $json = q{[
    {"sku": "orange", "images": ["orange.jpg", "orange.png"]},
    {"sku": "pomelo", "images": ["pomelo.jpg", "pomelo.png"]}
    ]};

    my ($json_fh, $json_file) = tempfile;
    print $json_fh $json, "\n";
    close $json_fh;

    my $json_file_iter = Template::Flute::Iterator::JSON->new(
        file => $json_file, selector => '*', children => 'unknown');
    isa_ok $json_file_iter, 'Template::Flute::Iterator';
    is $json_file_iter->count, 0, "Unknown children seeds iterator with empty list";

    $json_file_iter = Template::Flute::Iterator::JSON->new(
        file => $json_file, selector => '*', children => 'images');
    isa_ok $json_file_iter, 'Template::Flute::Iterator';
    is $json_file_iter->count, 4,
        "Known children seeds iterator with total number of children elements";
};
