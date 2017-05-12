use Test::More;
plan tests => 9;

use Spark::Form;

#Local lib
use lib 't/lib';
use TestApp::Form::Field::Email;
use TestApp::Form::Field::Password;

#Create a form
my $form = Spark::Form->new;

my $email = TestApp::Form::Field::Email->new(name => 'email', form => $form);
my $pass1 = TestApp::Form::Field::Password->new(name => 'password', form => $form);
my $pass2 = TestApp::Form::Field::Password->new(name => 'confirm_password', confirm => 'password', form => $form);
my $email2 = TestApp::Form::Field::Email->new(name => 'email2', form => $form);

#Add fields and count them
$form->add($email)
     ->add($pass1)
     ->add($pass2, confirm => 'password')
     ->add($email2);
cmp_ok(scalar $form->fields, '==', 4, "Fields all added");

#Validate
$form->data({email => 'blah', password => 'password', confirm_password => 'foo', email2 => 'feh'});
$form->validate;
is(scalar $form->errors, 4, 'Four errors');

#Revalidate
$form->data({email => 'blah@blah.com', password => 'password', confirm_password => 'password', email2 => 'blah@blah.com'});
$form->validate;
is(scalar $form->errors, 0, 'No error');

my $form2 = $form->clone_except_names('email');
is_deeply([sort $form2->keys],[qw(confirm_password email2 password)],"Email field removed in clone");

my $form3 = $form->clone_only_names(qw(email email2));
is_deeply([sort $form3->keys],[qw(email email2)],"Two password fields removed in clone") || diag explain [[ $form3->keys], [$form->keys] ];


my $form4 = $form->clone_except_ids(1,2);
is_deeply([sort $form4->keys],[qw(email email2)],"Two email fields remain alone in clone");

my $form5 = $form->clone_only_ids(1,2);
is_deeply([sort $form5->keys],[qw(confirm_password password)],"Two password fields remain alone in clone") || diag explain [[ $form5->keys ], [$form->keys ]];

my $form6 = $form->clone_if(sub {
    $_[1] !~ /_/
});
is_deeply([sort $form6->keys],[qw(email email2 password)],"Two password fields remain alone in clone") ||
  diag explain [[ $form6->keys ], [ $form->keys] ];



my $form7 = $form->clone_unless(sub {
    $_[1] =~ /2$/
});
is_deeply([sort $form7->keys],[qw(confirm_password email password)],"Two password fields remain alone in clone");


#clone_if

#clone_unless
