use strict;
use warnings;

use Test::More;
use Object::eBay::Item;

eval "use Test::MockObject";
plan skip_all => "Test::MockObject required for testing Item->is_ended" if $@;

plan tests => 6;

# fake the selling_status method
my $mocked = Test::MockObject->new;
{
    no strict 'refs';
    no warnings 'redefine';
    *Object::eBay::Item::selling_status = sub { $mocked };
}

# test the normal cases
my %tests = (
    Active    => 'false',
    Completed => 'true',
    Ended     => 'true',
);
my $item = Object::eBay::Item->new({ item_id => 12345 });
while ( my ($value, $expected) = each %tests ) {
    $mocked->set_always( listing_status => $value );
    is $item->is_ended, $expected, "is_ended for $value";
}

$mocked->set_always( listing_status => 'Custom' );
eval { $item->is_ended };
like $@, qr/unknown listing status/, 'Custom';

$mocked->set_always( listing_status => 'CustomCode' );
eval { $item->is_ended };
like $@, qr/unknown listing status/, 'CustomCode';

$mocked->set_always( listing_status => undef );
eval { $item->is_ended };
like $@, qr/no listing status/, 'no status at all';
