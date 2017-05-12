use strict;
use warnings;
use Test::More tests => 5;

use Template::Refine::Fragment;
use Template::Refine::Processor::Rule;
use Template::Refine::Processor::Rule::Select::XPath;
use Template::Refine::Processor::Rule::Transform::Replace::WithText;

my $orig = '<p>Hello, <span class="world"/>.</p>';
my $frag = Template::Refine::Fragment->new_from_string(
    $orig,
);

ok $frag;
is $frag->render, $orig;

my $frag2 = $frag->process(
    Template::Refine::Processor::Rule->new(
        selector => Template::Refine::Processor::Rule::Select::XPath->new(
            pattern => '//*[@class="world"]',
        ),
        transformer => Template::Refine::Processor::Rule::Transform::Replace::WithText->new(
            replacement => sub {
                return 'world';
            },
        ),
    ),
);

ok $frag2;
is $frag2->render, '<p>Hello, <span class="world">world</span>.</p>';
is $frag->render, $orig, 'original fragment untouched';
