# Pragmas.
use strict;
use warnings;

# Modules.
use Tags::Utils::Preserve;
use Test::More 'tests' => 36;
use Test::NoWarnings;

# Test.
my $obj = Tags::Utils::Preserve->new;
my ($pre, $pre_pre) = $obj->get;
is($pre, 0);
is($pre_pre, 0);
($pre, $pre_pre) = $obj->begin('element');
is($pre, 0);
is($pre_pre, 0);
($pre, $pre_pre) = $obj->end('element');
is($pre_pre, 0);
is($pre, 0);

# Test.
$obj = Tags::Utils::Preserve->new(
	'preserved' => ['element'],
);
($pre, $pre_pre) = $obj->get;
is($pre, 0);
is($pre_pre, 0);
($pre, $pre_pre) = $obj->begin('other_element');
is($pre, 0);
is($pre_pre, 0);
($pre, $pre_pre) = $obj->begin('element');
is($pre, 1);
is($pre_pre, 0);
($pre, $pre_pre) = $obj->begin('other_element2');
is($pre, 1);
is($pre_pre, 1);
($pre, $pre_pre) = $obj->end('other_element2');
is($pre, 1);
is($pre_pre, 1);
($pre, $pre_pre) = $obj->end('element');
is($pre, 0);
is($pre_pre, 1);
($pre, $pre_pre) = $obj->end('other_element');
is($pre, 0);
is($pre_pre, 0);

# Test.
$obj->reset;
$pre = $obj->get;
is($pre, 0);
$pre = $obj->begin('other_element');
is($pre, 0);
$pre = $obj->begin('element');
is($pre, 1);
$pre = $obj->begin('other_element2');
is($pre, 1);
$pre = $obj->end('other_element2');
is($pre, 1);
$pre = $obj->end('element');
is($pre, 0);
$pre = $obj->end('other_element');
is($pre, 0);

# Test.
$obj->reset;
$obj->begin('other_element');
$obj->begin('element');
$obj->begin('other_element2');
($pre, $pre_pre) = $obj->get;
is($pre, 1);
is($pre_pre, 1);
$obj->reset;
($pre, $pre_pre) = $obj->get;
is($pre, 0);
is($pre_pre, 0);

# Test.
$obj->reset;
$obj->begin('other_element');
($pre, $pre_pre) = $obj->begin('element');
is($pre, 1);
is($pre_pre, 0);
$obj->save_previous;
($pre, $pre_pre) = $obj->get;
is($pre, 1);
is($pre_pre, 1);
