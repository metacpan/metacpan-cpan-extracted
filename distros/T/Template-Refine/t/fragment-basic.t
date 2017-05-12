use strict;
use warnings;
use Test::More tests => 2;

use Template::Refine::Fragment;

my $frag = Template::Refine::Fragment->new_from_string(
    '<p>This is a <b>test</b>.'
);

isa_ok $frag, 'Template::Refine::Fragment';

is $frag->render, '<p>This is a <b>test</b>.</p>';
