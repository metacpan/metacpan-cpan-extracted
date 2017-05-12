use Test::More tests => 2;
use_ok('Parse::BBCode');
use strict;
use warnings;

my $p = Parse::BBCode->new({
        direct_attribute => 0,
        tags => {
            'a' => {
                parse => 1,
                code => sub {
                    my ($parser, $attr, $content, $attribute_fallback, $token) = @_;
                    my $at = $token->get_attr;
                    my $href = "";
                    for my $item (@$at) {
                        if ($item->[0] eq 'href') {
                            $href = $item->[1];
                            last;
                        }
                    }
                    return qq{<a href="$href">$$content</a>};
                },
            },
        },
});

my @tests = (
    [ q#[a href="foo"]link[/a]#,
        q#<a href="foo">link</a># ],
);

for (@tests) {
    my ($in, $exp) = @$_;
    my $parsed = $p->render($in);
    #warn __PACKAGE__.':'.__LINE__.": $parsed\n";
    cmp_ok($parsed, 'eq', $exp, "$in");
}

