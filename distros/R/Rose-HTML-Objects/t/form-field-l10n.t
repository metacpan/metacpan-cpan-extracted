#!/usr/bin/perl -w

use strict;

use Test::More tests => 43;

use FindBin qw($Bin);

use lib "$Bin/lib";

use Rose::HTML::Object::Errors qw(CUSTOM_ERROR FIELD_REQUIRED);
use Rose::HTML::Object::Messages qw(CUSTOM_MESSAGE FIELD_REQUIRED_GENERIC);

BEGIN
{
  use_ok('Rose::HTML::Form::Field');
  use_ok('MyField');
}

use MyObject::Messages qw(:all);

my $o = MyField->new;

$o->localize_label;
$o->localize_description;

is($o->label, 'Dog', 'localized label 1');
$o->locale('xx');
is($o->label, 'Chien', 'localized label 2');

MyField->localizer->add_localized_message_text( 
  name => 'FIELD_LABEL',
  text => 
  {
    en => 'Cat',
    xx => 'Chat',
  });

is($o->label, 'Chat', 'localized label 3');
$o->locale('en');
is($o->label, 'Cat', 'localized label 4');

$o->label('Cow');

is($o->label, 'Cow', 'unlocalized label 1');
$o->locale('xx');
is($o->label, 'Cow', 'unlocalized label 2');

if($^V lt v5.8.7)
{
  if($^V ge v5.8.0)
  {
    no warnings 'uninitialized';
    my $desc = $o->description;
    is("$desc", '', 'localized description 1 (5.8.0-7)');  
  }
  else
  {
    # XXX: This causes perl 5.6.x to segfault on me.  Blah.
    #is("$desc", '', 'localized description 1 (<5.8.7)');  
    #no warnings 'uninitialized';
    #my $desc = $o->description;
    SKIP: { skip('localized description in perl < 5.8.7', 1); }
  }
}
else
{
  # XXX: This works fine for me in 5.8.8...
  # XXX: Now (7/16/07) set to empty string.  Dunno if bug remains.
  is($o->description, '', 'localized description 1 (5.8.8+)');
}

my $id = MyField->localizer->add_localized_message( 
  name => 'EMAIL_FIELD_LABEL',
  text => 
  {
    en => 'Email',
    xx => 'Courriel',
  });

$o->label_message_id($id);

$o->locale('en');
is($o->label, 'Email', 'new localized label 1');
$o->locale('xx');
is($o->label, 'Courriel', 'new localized label 2');

$id = MyField->localizer->add_localized_message( 
  name => 'NAME_FIELD_LABEL',
  text => 
  {
    en => 'Name',
    xx => 'Nom',
  });

#$Rose::HTML::Object::Exporter::Debug = 1;
MyField->localizer->import_message_ids(':all');
#$Rose::HTML::Object::Exporter::Debug = 0;

$o->label_message_id(NAME_FIELD_LABEL());

$o->locale('en');
is($o->label, 'Name', 'new localized label 3');
$o->locale('xx');
is($o->label, 'Nom', 'new localized label 4');

$o->locale('en');

# has_error(s)
ok(!$o->has_error, 'has_error 1');
ok(!$o->has_errors, 'has_errors 1');

# errors
$o->errors('Error one', 'Error two');

ok($o->has_error, 'has_error 2');
ok($o->has_errors, 'has_errors 2');

my @errors = $o->errors;
is(scalar @errors, 2, 'errors 1');
is_deeply([ map { "$_" } @errors ], [ 'Error one', 'Error two' ], 'errors 2');
is_deeply([ map { $_->id } @errors ], [ CUSTOM_ERROR, CUSTOM_ERROR ], 'errors 3');
my $error = $o->error;
is($error->id, CUSTOM_ERROR, 'errors 4');

# error_id
is($o->error_id, CUSTOM_ERROR, 'error_id 1');
is_deeply([ $o->error_ids ], [ CUSTOM_ERROR, CUSTOM_ERROR ], 'error_ids 1');

# add_error
$o->add_error(FIELD_REQUIRED);
@errors = $o->errors;
is_deeply([ map { "$_" } @errors ], [ 'Error one', 'Error two', 'This is a required field.' ], 'add_error 1');
is_deeply([ map { $_->id } @errors ], [ CUSTOM_ERROR, CUSTOM_ERROR, FIELD_REQUIRED ], 'add_error 2');

# add_error_ids
$o->errors(FIELD_REQUIRED, 'Error two');
$o->add_error_ids(FIELD_REQUIRED, FIELD_REQUIRED);
@errors = $o->errors;
is_deeply([ map { "$_" } @errors ], [ 'This is a required field.', 'Error two', 
          'This is a required field.', 'This is a required field.' ], 'add_error_ids 1');
is_deeply([ map { $_->id } @errors ], [ FIELD_REQUIRED, CUSTOM_ERROR, FIELD_REQUIRED, FIELD_REQUIRED ], 'add_error_ids 2');

# add_error_id
$o->errors(FIELD_REQUIRED, 'Error two');
$o->add_error_id(FIELD_REQUIRED);
@errors = $o->errors;
is_deeply([ map { "$_" } @errors ], [ 'This is a required field.', 'Error two', 
          'This is a required field.', ], 'add_error_id 1');
is_deeply([ map { $_->id } @errors ], [ FIELD_REQUIRED, CUSTOM_ERROR, FIELD_REQUIRED, ], 'add_error_id 2');

ok($o->has_error, 'has_error 3');
ok($o->has_errors, 'has_errors 3');

$o->error('Foo');
@errors = $o->errors;
is(scalar @errors, 1, 'error 1');

ok($o->has_error, 'has_error 4');
ok($o->has_errors, 'has_errors 4');

$o->error(undef);
ok(!$o->has_error, 'has_error 5');
ok(!$o->has_errors, 'has_errors 5');

$o->errors('foo', 'bar');
$o->errors(undef);
ok(!$o->has_error, 'has_error 6');
ok(!$o->has_errors, 'has_errors 6');

$o->errors('foo');
$o->errors([]);
ok(!$o->has_error, 'has_error 7');
ok(!$o->has_errors, 'has_errors 7');

$o->error_label('Foo');
$o->required(1);
$o->clear;
$o->validate;
is($o->error, 'Foo is a required field.', 'error label 1');

$o->error_label('');
$o->validate;
is($o->error, 'This is a required field.', 'error label 2');

$o = Rose::HTML::Form::Field->new(name => 'test', required => 1);
$o->locale('bg');
$o->validate;

$error = $o->error;
# XXX: This fails for mysterious reasons in some installations of perl
#is(length($error), 25, 'localized error length');

is(length("$error"), 25, 'localized error length');

#is(length($error->message->as_string), 25, 'localized error length');
