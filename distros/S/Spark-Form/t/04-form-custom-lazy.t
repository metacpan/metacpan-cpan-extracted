# Test custom fields
use Test::More tests => 9;

use lib 't/lib';
use Spark::Form;

#Create a form
my $form = Spark::Form->new(plugin_ns => 'TestApp::Form::Field');

#First off, verify there are no fields in an empty form
is_deeply([$form->fields], [], "Fields are not yet populated");

#Add two custom fields
$form->add('custom', 'gt6', min_length => 6);
cmp_ok(scalar $form->fields, '==', 1, "Custom field 1 added");
$form->add('custom', 'gt2', min_length => 2);
cmp_ok(scalar $form->fields, '==', 2, "Custom field 2 added");

#DATASET 1 - two fail
my %data = (
    gt6 => '1',
    gt2 => '1',
);
$form->data(\%data);
$form->validate;
cmp_ok($form->valid,         '==', 0, "Dataset 1 is invalid");
cmp_ok(scalar $form->errors, '==', 2, "Dataset 1 has 2 errors");

#DATASET 2 - one fail
%data = (
    gt6 => '12',
    gt2 => '12',
);
$form->data(\%data);
$form->validate;
cmp_ok($form->valid,         '==', 0, "Dataset 2 is invalid");
cmp_ok(scalar $form->errors, '==', 1, "Dataset 2 has 1 error");

#DATASET 3 - No errors
%data = (
    gt6 => '123456',
    gt2 => '12',
);
$form->data(\%data);
$form->validate;
cmp_ok($form->valid, '==', 1, "Dataset 3 is valid");
is_deeply([$form->errors], [], "Dataset 3 has no errors");
