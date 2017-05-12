#
# Tests for list paging
#

use strict;
use warnings;

use Test::More;
use Data::Dumper;

use Data::Transpose::Iterator::Scalar;
use Template::Flute;

my ($spec, $html, $flute, $iter, $out, @dangling);

$spec = q{<specification>
<list name="numbers" iterator="numbers">
<param name="value"/>
</list>
<paging name="numbers" list="numbers" class="paging">
<element name="first" type="first"/>
<element name="previous" type="previous" class="previous"/>
<element name="next" type="next"/>
<element name="last" type="last" class="paging-last"/>
<element name="standard" type="standard" class="standard"/>
<element name="active" type="active"/>
</paging>
</specification>
};

$html = q{
<div class="numbers">
<div class="value">0</div>
</div>

<div class="paging">
<ul>
    <li class="previous"><a href="">Previous</a></li>
	<li class="active"><a href="">3</a></li>
    <li class="first"><a href="">First</a></li>
	<li class="standard"><a href="">2</a></li>
	<li class="standard"><a href="">23</a></li>
	<li class="standard"><a href="">24</a></li>
	<li class="last"><a href="">25</a></li>
	<li class="next"><a href="">Next</a></li>
</ul>
</div>
};

my @tests = ({count => 10, page_size => 20},
         {count => 40, page_size => 20});

plan tests => scalar @tests * 2;

for my $t (@tests) {
    $iter = Data::Transpose::Iterator::Scalar->new([1..$t->{count}]);

    $flute = Template::Flute->new(
        template => $html,
        specification => $spec,
        auto_iterators => 1,
        values => {numbers => $iter},
    );

    $out = $flute->process;
    @dangling = $flute->specification->dangling;

    ok (! scalar(@dangling), "Dangling check")
        || diag "Dangling: ", Dumper(\@dangling);

    # check whether paging container is present or not
    if ($t->{count} < $t->{page_size}) {
        ok ($out !~ m%<div class="paging">.*</div>%,
            "Search without paging")
            || diag "Out: $out.";
    }
    else {
         ok ($out =~ m%<div class="paging">(.*)</div>%,
             "Search with paging")
             || diag "Out: $out.";
#         warn "Match: $1.\n";
     }
};
