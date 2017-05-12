# Something looking a bit more real-world
use Test::More;
plan tests => 12;

use Spark::Form;

#Local lib
use lib 't/lib';
use TestApp::Form::Field::Email;
use TestApp::Form::Field::Password;

#Create a form
my $form = Spark::Form->new;
my $form2 = Spark::Form->new;
my $email = TestApp::Form::Field::Email->new(name => 'email', form => $form);
my $pass1 = TestApp::Form::Field::Password->new(name => 'password', form => $form2);
my $pass2 = TestApp::Form::Field::Password->new(name => 'confirm_password', confirm => 'password', form => $form2);

#Add an email
$form->add($email);
cmp_ok(scalar $form->fields, '==', 1, "Email field added");

#Add a password
$form2->add($pass1);
cmp_ok(scalar $form2->fields, '==', 1, "Password field added");
#And a confirm password
$form2->add($pass2, confirm => 'password');
cmp_ok(scalar $form2->fields, '==', 2, "Password confirm field added");

#Clone and check field count
$form3 = $form->compose($form2);

#Check field counts
cmp_ok(scalar $form->fields, '==', 1, "First form still has one field");
cmp_ok(scalar $form2->fields, '==', 2, "Second form still has two fields");
cmp_ok(scalar $form3->fields, '==', 3, "Check new field count");

#Validate form 1
$form->data({email => 'blah'});
$form->validate;
is(scalar $form->errors, 1, 'One error');

#Validate form 2
$form2->data({password => 'password', confirm_password => 'foo'});
$form2->validate;
is(scalar $form2->errors, 2, 'Two errors');

#Validate form 3
$form3->data({email => 'blah', password => 'password', confirm_password => 'foo'});
$form3->validate;
is(scalar $form3->errors, 3, 'Three error');
#Revalidate
$form3->data({email => 'blah@blah.com', password => 'password', confirm_password => 'password'});
$form3->validate;
is(scalar $form3->errors, 0, 'No errors');
#Revalidate first two forms
$form->validate;
is(scalar $form->errors, 1, 'Still one error');
$form2->validate;
is(scalar $form2->errors, 2, 'Still two errors');
