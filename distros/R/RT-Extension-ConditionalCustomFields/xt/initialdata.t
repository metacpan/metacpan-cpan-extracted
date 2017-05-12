use strict;
use warnings;

use RT::Extension::ConditionalCustomFields::Test tests => 9;

my $firstinitialdata = RT::Test::get_relocatable_file("firstcf" => "data");
my ($rv, $msg) = RT->DatabaseHandle->InsertData( $firstinitialdata, undef, disconnect_after => 0 );
ok($rv, "Inserted test data from $firstinitialdata: $msg");

my $initialdata = RT::Test::get_relocatable_file("initialdata" => "data");
($rv, $msg) = RT->DatabaseHandle->InsertData( $initialdata, undef, disconnect_after => 0 );
ok($rv, "Inserted test data from $initialdata: $msg");

my $attributes = RT::Attributes->new(RT->SystemUser);
$attributes->Limit(FIELD => 'Name', VALUE => 'ConditionedBy');
is($attributes->Count, 3, 'All attributes created');
while (my $attribute = $attributes->Next) {
    if ($attribute->id == 7) {
        is($attribute->Content, , 3, 'First ConditionedBy attribute content');
    } elsif ($attribute->id == 8) {
        is($attribute->Content, 3, 'Second ConditionedBy attribute content');
    } elsif ($attribute->id == 9) {
        is($attribute->Content, 1, 'Third ConditionedBy attribute content');
    }
    else {
        is($attribute->id, '7 or 8 or 9', 'Unexpected attribute id')
    }

}
