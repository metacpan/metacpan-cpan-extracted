use strict;
use warnings;

use RT::Extension::ConditionalCustomFields::Test tests => 16;

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
        is($attribute->Content->{CF}, 3, 'First ConditionedBy CF');
        is(scalar(@{$attribute->Content->{vals}}), 1, 'First ConditionedBy one val');
        is($attribute->Content->{vals}->[0], 'Passed', 'First ConditionedBy val');
    } elsif ($attribute->id == 8) {
        is($attribute->Content->{CF}, 3, 'Second ConditionedBy CF');
        is(scalar(@{$attribute->Content->{vals}}), 1, 'Second ConditionedBy one val');
        is($attribute->Content->{vals}->[0], 'Passed', 'Second ConditionedBy val');
    } elsif ($attribute->id == 9) {
        is($attribute->Content->{CF}, 3, 'Third ConditionedBy CF');
        is(scalar(@{$attribute->Content->{vals}}), 2, 'Third ConditionedBy one val');
        is($attribute->Content->{vals}->[0], 'Passed', 'Third ConditionedBy first val');
        is($attribute->Content->{vals}->[1], 'Schrödingerized', 'Third ConditionedBy second val');
    } else {
        is($attribute->id, '7 or 8 or 9', 'Unexpected attribute id');
    }
}
