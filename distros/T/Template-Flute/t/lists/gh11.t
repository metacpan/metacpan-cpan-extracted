#
# Test for Github issue #11
#

use strict;
use warnings;

use Test::More;
use Test::Warnings;

use Template::Flute;

my ($spec, $html, $iter, $flute, $out);

$spec = q{<specification><list name="field" iterator="fields">
<param name="field" />
<param name="label" class="field-label" />
<param name="class" class="field-label" target="class" op="append" joiner=" " />
<param name="sort" class="field-label" field="field" target="href" op="append" />
</list></specification>};

$html = q{
<table>
<thead><tr>
<th class="field"><a href="/admin/sort/" class="field-label"></a></th>
</tr></thead>
</table>
};

$iter = [
{
'label' => 'UID',
'field' => 'uid'
},
{
'class' => 'selected',
'label' => 'Username',
'field' => 'username'
},
{
'label' => 'Status',
'field' => 'status'
},
{
'class' => undef,
'label' => 'Active',
'field' => 'active'
},
];

$flute = Template::Flute->new(
    template => $html,
    specification => $spec,
#    auto_iterators => 1,
    values => {fields => $iter},
);

$out = $flute->process();

my @lists = $flute->template->lists;
my $ct = scalar(@lists);

ok($ct == 1, "Number of lists") ||
    diag "Wrong number of lists: $ct instead of 1.";

isa_ok($lists[0], 'Template::Flute::List');

my $name = $lists[0]->name;

ok($name eq 'field', 'List name')
    || diag "Wrong name of the list: $name instead of field";

# count number of matches of class="... selected"
my @matches = $out =~ /(class=".*?\bselected\b.*?")/g;
$ct = scalar(@matches);

ok($ct == 1, 'Number of matches for "selected" in class.')
    || diag "Wrong number of matches: $ct instead of 1.";

done_testing;
