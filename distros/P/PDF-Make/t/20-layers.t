#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 15;

BEGIN {
    use_ok('PDF::Make::Document');
    use_ok('PDF::Make::Canvas');
    use_ok('PDF::Make::Layer');
}

my $doc = PDF::Make::Document->new;
my $page = $doc->add_page(612, 792);

# Create layers
my $layer1 = PDF::Make::Layer->create($doc, 'Dimensions');
ok($layer1, 'layer created');
is($layer1->name, 'Dimensions', 'layer name');
like($layer1->res_name, qr/^MC\d+$/, 'resource name format');
is($layer1->visible, 1, 'default visible');

my $layer2 = PDF::Make::Layer->create($doc, 'Annotations');
$layer2->visible(0);
is($layer2->visible, 0, 'set invisible');

# Write OCG objects
my $num1 = $layer1->write_to_doc($doc);
ok($num1 > 0, 'layer1 written');
my $num2 = $layer2->write_to_doc($doc);
ok($num2 > 0, 'layer2 written');
isnt($num1, $num2, 'different object numbers');

# Register on page
$page->add_ocg($layer1->res_name, $num1);
$page->add_ocg($layer2->res_name, $num2);

# Draw with layers
my $c = PDF::Make::Canvas->new;
$c->begin_layer($layer1->res_name)
  ->m(72, 600)->l(300, 600)->S
  ->end_layer;
$page->set_content($c->to_bytes);

# Verify PDF
my $bytes = $doc->to_bytes;
like($bytes, qr/OCProperties/, 'PDF has /OCProperties');
like($bytes, qr/\/Type \/OCG/, 'PDF has /Type /OCG');
like($bytes, qr/Dimensions/, 'OCG has name Dimensions');
like($bytes, qr/\/Properties/, 'page has /Properties resource');

done_testing;
