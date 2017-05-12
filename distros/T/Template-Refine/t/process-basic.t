use strict;
use warnings;
use Test::More tests => 5;

use ok 'Template::Refine::Processor::Rule::Transform::Replace::WithText';
use ok 'Template::Refine::Processor::Rule::Select::CSS';
use ok 'Template::Refine::Processor::Rule';
use ok 'Template::Refine::Fragment';

my $doc = Template::Refine::Fragment->new_from_string('<div><p>Foo</p><p>Bar</p></div>');

my $rule = Template::Refine::Processor::Rule->new(
    transformer => Template::Refine::Processor::Rule::Transform::Replace::WithText->new(
        replacement => sub { 'OH HAI' },
    ),
    selector => Template::Refine::Processor::Rule::Select::CSS->new(
        pattern => 'p',
    ),
);

my $new_doc = $doc->process($rule);

is $new_doc->render, '<div><p>OH HAI</p><p>OH HAI</p></div>';
