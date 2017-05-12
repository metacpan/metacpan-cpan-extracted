#
# Tests for lists sharing the same iterator
#

use strict;
use warnings;

use Test::More;
use Template::Flute;

my $spec = q{
<specification>
<list name="view-compact" class="product-box-compact" iterator="products">
<param name="name" class="product-name"/>
</list>
<list name="view-grid" class="navigation-view-grid" iterator="products">
<param name="name" class="product-name"/>
</list>
</specification>
};

my $html = q{
<div class="product-box-compact">
<a href="/" class="product-name">Organic gift basket for babies</a>
</div>
<div class="navigation-view-grid">
<a href="/" class="product-name">Organic gift basket for babies</a>
</div>
};

my $products = [{name => 'Blue ball'}];

my $flute = Template::Flute->new(specification => $spec,
                                 template => $html,
                                 iterators => {
                                     products => $products,
                                 },
                             );

my $out = $flute->process;

# check number of lists
my @lists = sort {$a->name cmp $b->name} $flute->template->lists;
my $count = scalar @lists;

ok ($count == 2, 'Test number of lists');

# test list names
my $name = $lists[0]->name;

ok ($name eq 'view-compact', 'Test name of first list')
    || diag "Name of first list: ", $name, " instead of view-compact";

$name = $lists[1]->name;

ok ($name eq 'view-grid', 'Test name of second list')
    || diag "Name of second list: ", $name, " instead of view-grid";

# test iterator names
my $iterator = $lists[0]->iterator('name');

ok ($iterator eq 'products', 'Test iterator of first list')
    || diag "Iterator of first list: ", $iterator;

$iterator = $lists[1]->iterator('name');

ok ($iterator eq 'products', 'Test iterator of second list')
    || diag "Iterator of second list: ", $iterator;

# check output

my @matches = $out =~ /Blue ball/g;

ok (@matches == 2, 'Test replacement in both lists')
    || diag "Matches: ", scalar(@matches), "Output: $out";

done_testing;
