use Test::More tests => 1;

use Spark::Form;

#Create a form
my $form = Spark::Form->new;

isa_ok($form->field_couplet,'Data::Couplet','Correct type for field_couplet accessor');