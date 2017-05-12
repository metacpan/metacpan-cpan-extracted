#! perl
#
# Test for containers inside of lists.

use strict;
use warnings;

use Test::More tests => 4;
use Template::Flute;

my ($spec, $html, $flute, $out);

$spec = q{
<specification>
<list name="products" iterator="cart">
<param name="sku"/>
<container name="color" value="color">
<param name="color"/>
</container>
</list>
</specification>
};

$html = q{
<ul>
<li class="products">
<span class="sku">000</span>
<span class="color">white</span>
</li>
</ul>
};

my @products = (
    {sku => '123'},
    {sku => '456', color => 'black'},
);

$flute = Template::Flute->new(template => $html,
                              specification => $spec,
                              iterators => {cart => \@products},
    );

$out = $flute->process();

my @ct_arr = $flute->template->containers;
my $ct_count = scalar @ct_arr;

ok ($ct_count == 1, 'Test for container count')
    || diag "Wrong number of containers: $ct_count\n";

my $ct = $ct_arr[0];
my $ct_name = $ct->name;
my $ct_list = $ct->list;

ok ($ct_name eq 'color', 'Test for container name')
    || diag "Wrong container name: $ct_name\n";

ok ($ct_list eq 'products', 'Test for container list')
    || diag "Wrong container list: $ct_list\n";

ok ($out =~ m%<ul><li class="products"><span class="sku">123</span></li><li class="products"><span class="sku">456</span><span class="color">black</span></li></ul>%, 'Test for container within list.')
    || diag "Mismatch on elements: $out";


