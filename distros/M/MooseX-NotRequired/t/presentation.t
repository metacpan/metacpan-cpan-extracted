use Test::Most;
SKIP: {
    eval { require DateTime };
        skip('These tests are optional extras that can be enabled by installing DateTime', 1) if $@;

{
    package SalesOrder;

    use Moose;

    has order_number    => (is => 'ro', isa => 'Str', required => 1);
    has reference       => (is => 'ro', isa => 'Str' );
    has date_ordered    => (is => 'ro', isa => 'DateTime', required => 1);
    has total_value     => (is => 'ro', isa => 'Int', required => 1);
    has customer        => (is => 'ro', isa => 'Str', required => 1);
    has notes           => (is => 'ro', isa => 'Str');

    1;
}

use MooseX::NotRequired;

throws_ok 
{
    my $old_class = SalesOrder->new();
} qr'Attribute.*is required'i, 
    'Type constraints still work on original class';

ok my $o = SalesOrder->new({ 
    order_number    => 'SO0001', 
    reference       => '000232', 
    date_ordered    => DateTime->today,
    total_value     => 10,
    customer        => 'OpusVL',
}) => 'Can construct the object normally';

my $new_class = MooseX::NotRequired::make_optional_subclass('SalesOrder');

# check we can now provide an undef despite Str constraint.
# also missing required parameters.

ok my $no = $new_class->new({ total_value => 4, notes => undef}),
    'Constraints have been weakened';
is $no->total_value, 4, 'Attribute set correctly';
ok !$no->notes, "Required parameter really isn't set";

ok my $defaults = $new_class->new({ order_number => 'SO0002' });

throws_ok 
{
    my $old_class = SalesOrder->new();
} qr'Attribute.*is required'i, 
    'Constraints still work on original class';

# check setting Str to undef blows up on original class.
throws_ok 
{
    my $old_class = SalesOrder->new({ 
        order_number    => 'SO0001', 
        reference       => '000232', 
        date_ordered    => DateTime->today,
        total_value     => 'a',
        notes           => undef 
    });
} qr'does not pass the type constraint because|Attribute \(customer\) is required'i, 
    'Type constraints still work on original class';

# and lets prove that the type restrictions preventing
# us sticking a string into an Int attribute still
# apply to the new class too.
throws_ok 
{
    my $old_class = $new_class->new({ 
        order_number    => 'SO0001', 
        reference       => '000232', 
        date_ordered    => DateTime->today,
        total_value     => 'a',
        notes           => undef 
    });
} qr'does not pass the type constraint because'i, 
    'Type constraints still work on original class';

};
done_testing;

