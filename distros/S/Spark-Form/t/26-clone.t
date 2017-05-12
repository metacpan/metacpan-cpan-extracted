use Test::More tests => 5;

use Spark::Form;
use Data::Dumper 'Dumper';

#Local lib
use lib 't/lib';
use TestApp::Form::Field::Email;
use TestApp::Form::Field::Password;

#Create a form
my $form = Spark::Form->new;

my $email = TestApp::Form::Field::Email->new(name => 'email', form => $form);
my $pass1 = TestApp::Form::Field::Password->new(name => 'password', form => $form);
my $pass2 = TestApp::Form::Field::Password->new(name => 'confirm_password', confirm => 'password', form => $form);

#Add an email
$form->add($email);
#Add a password
$form->add($pass1);
#And a confirm password
$form->add($pass2, confirm => 'password');
cmp_ok(scalar $form->fields, '==', 3, "3 fields added");

my $other_form = $form->clone_all();


#Validate
$form->data({email => 'blah', password => 'password', confirm_password => 'foo'});
$form->validate;
is(scalar $form->errors, 3, 'Three errors on original form');

$other_form->data({email => 'blah', password => 'password', confirm_password => 'foo'});
$other_form->validate;
is(scalar $other_form->errors, 3, 'Three errors on cloned form');

#Revalidate
$other_form->data({email => 'blah@blah.com', password => 'password', confirm_password => 'password'});
$other_form->validate;
is(scalar $other_form->errors, 0, 'No error on cloned form');

#Check it hasn't tampered with the existing form
$form->validate;
is(scalar $form->errors, 3, 'Three errors on original form still');
