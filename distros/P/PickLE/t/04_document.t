#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 11;

use PickLE::Category;
use PickLE::Component;
BEGIN { use_ok('PickLE::Document'); }

# Slurps a file.
sub slurp {
    my ($filename) = @_;

    open my $fh, '<:encoding(UTF-8)', $filename or die;
    local $/ = undef;
    my $content = <$fh>;
    close $fh;

    return $content;
}

# Blank start.
my $doc = new_ok('PickLE::Document');
ok $doc->as_string eq '', 'as_string is empty for a blank object';

# Checking for the required properties.
$doc->add_property(PickLE::Property->new(name => 'Name', value => 'Test'));
ok $doc->as_string eq '', 'as_string still empty after adding Name property';
$doc->add_property(PickLE::Property->new(name => 'Revision', value => 'A'));
ok $doc->as_string eq '', 'as_string still empty after adding Revision property';
$doc->add_property(PickLE::Property->new(name => 'Description', value => 'Test'));
ok $doc->as_string eq "Name: Test\nRevision: A\nDescription: Test\n\n---\n\n",
	'as_string properly returned after adding Description property';

# Categories
is_deeply $doc->categories, [], 'categories initialized as an empty array';
$doc->add_category(PickLE::Category->new);
is scalar(@{$doc->categories}), 1, '1 category in the array';
$doc->add_category(PickLE::Category->new);
is scalar(@{$doc->categories}), 2, '2 categories in the array';

# Parsing
$doc = PickLE::Document->load('contrib/example.pkl');
isa_ok $doc, 'PickLE::Document';
$doc = PickLE::Document->from_string(slurp('contrib/example.pkl'));
isa_ok $doc, 'PickLE::Document';
