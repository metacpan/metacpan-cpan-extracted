use strict;
use warnings;
use Test::More;
use Mojo::DOM;
use Mojo::JSON qw(true false encode_json);

my $dom = Mojo::DOM->with_roles('+AttrAccessors')
                   ->new('<div>')
                   ->at('div');

subtest 'boolean refs round-trip as Mojo::JSON booleans' => sub {
    $dom->data('flag', \1);
    my $val = $dom->data('flag');
    ok $val,       '\1 comes back truthy';
    is ref $val, ref true, '\1 comes back as Mojo::JSON boolean object';

    $dom->data('flag', \0);
    $val = $dom->data('flag');
    ok !$val,      '\0 comes back falsy';
    is ref $val, ref false, '\0 comes back as Mojo::JSON boolean object';
};

subtest 'Mojo::JSON booleans round-trip correctly' => sub {
    $dom->data('flag', true);
    my $val = $dom->data('flag');
    ok $val,       'true comes back truthy';
    is ref $val, ref true, 'true comes back as Mojo::JSON boolean object';

    $dom->data('flag', false);
    $val = $dom->data('flag');
    ok !$val,      'false comes back falsy';
    is ref $val, ref false, 'false comes back as Mojo::JSON boolean object';
};

subtest '\1 and true are not the same going in but are equivalent coming out' => sub {
    $dom->data('a', \1);
    $dom->data('b', true);
    is $dom->attr('data-a'), $dom->attr('data-b'), 'both store "true" in the attribute';
    ok $dom->data('a') && $dom->data('b'), 'both come back truthy';
};

done_testing;