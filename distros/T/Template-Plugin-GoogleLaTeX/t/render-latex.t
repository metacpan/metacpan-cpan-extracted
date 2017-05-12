#!perl -T

use strict; use warnings;

use Test::More tests => 2;
use Template;

my @templates;
push @templates, {
    template => <<EO_TEMPLATE,
[%- USE GoogleLaTeX -%]
[%- FILTER latex -%]
\\LaTeX
[%- END -%]
EO_TEMPLATE
    expected => '<img src="http://chart.apis.google.com/chart?cht=tx&amp;chl=%5CLaTeX">',
    desc => '\\LaTeX (HTML mode)'
}, {
    template => <<EO_TEMPLATE,
[%- USE GoogleLaTeX xhtml => 1 -%]
[%- FILTER latex -%]
\\LaTeX
[%- END -%]
EO_TEMPLATE
    expected => '<img src="http://chart.apis.google.com/chart?cht=tx&amp;chl=%5CLaTeX"/>',
    desc => '\\LaTeX (XHTML mode)',
};

for my $t ( @templates ) {
    my $tt = Template->new;

    $tt->process( \ $t->{template}, {}, \ my $result)
        or die $tt->error;

    is($result, $t->{expected}, $t->{desc});
};


