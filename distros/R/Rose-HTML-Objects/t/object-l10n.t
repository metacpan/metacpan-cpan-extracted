#!/usr/bin/perl -w

use strict;

use Test::More tests => 56;

use FindBin qw($Bin);

use lib "$Bin/lib";

use Rose::HTML::Object::Errors qw(CUSTOM_ERROR FIELD_REQUIRED);
use Rose::HTML::Object::Messages qw(CUSTOM_MESSAGE);

BEGIN
{
  use_ok('Rose::HTML::Object');
  use_ok('MyObject');
  use_ok('MyObject2');
  use_ok('MyObject::Messages');
  use_ok('MyObject::Messages2');
  use_ok('MyObject::Errors');
  use_ok('MyObject::Errors2');
}

is(Rose::HTML::Object->localizer->locale, 'en', 'default_locale 1');

my $o = Rose::HTML::Object->new;
is($o->locale, 'en', 'locale 1');

Rose::HTML::Object->localizer->locale('xx');
is($o->locale, 'xx', 'locale 2');

$o = Rose::HTML::Object->new;
is($o->locale, 'xx', 'locale 3');

$o->error('test error');

is(ref $o->error, 'Rose::HTML::Object::Error', 'error 1');
is($o->error->id, CUSTOM_ERROR, 'error id 1');
ok($o->error->is_custom, 'error is_custom 1');

is($o->error->message->id, CUSTOM_MESSAGE, 'error message id 1');
ok($o->error->message->is_custom, 'error message is_custom 1');

is($o->error . '', 'test error', 'error string 1');
is($o->error->message . '', 'test error', 'error message string 1');

Rose::HTML::Object->localizer->locale('en');

$o->errors('Error one', 'Error two');
my @errors = $o->errors;
is(scalar @errors, 2, 'errors 1');
is_deeply([ map { "$_" } @errors ], [ 'Error one', 'Error two' ], 'errors 2');
is_deeply([ map { $_->id } @errors ], [ CUSTOM_ERROR, CUSTOM_ERROR ], 'errors 3');
my $error = $o->error;
is($error->id, CUSTOM_ERROR, 'errors 4');

#
# Localized message and error
#

my $id = $o->localizer->add_localized_message(name => 'MY_MSG', text => 'my message');
is($id, 100_002, 'add_localized_message 1');

$id = $o->localizer->add_localized_error(name => 'MY_ERROR');
is($id, 100_003, 'add_localized_error 1');

$id = $o->localizer->add_localized_message(name => 'BUMMER', text => 'a bummer');
$o->localizer->add_localized_error(name => 'BUMMER', id => $id);

$o->error_id($id);
is($o->error->id, $id, 'localized error id 1');
ok(!$o->error->is_custom, 'localized error is_custom 1');

is($o->error . '', 'a bummer', 'localized error 1');

#
# Localized message text
#

# Scalar text

Rose::HTML::Object->localizer->locale('en');
$o->locale('xx');

is($o->locale, 'xx', 'object locale');
is(Rose::HTML::Object->locale, 'en', 'class locale');

$o->localizer->add_localized_message_text(name => 'BUMMER', locale => 'xx', text => 'le bummer');
is($o->error . '', 'le bummer', 'localized error 2');

$o->localizer->add_localized_message_text(name => 'BUMMER', locale => 'en', text => 'a bummer 2');
$o->locale('en');
is($o->error . '', 'a bummer 2', 'localized error 3');

# Hash text

$id = $o->localizer->add_localized_message(name => 'DOOM', 
                                text => { en => 'doom', xx => 'le doom' });
$o->localizer->add_localized_error(name => 'DOOM', id => $id);

$o->error_id($id);
is($o->error->id, $id, 'localized error id 2');
ok(!$o->error->is_custom, 'localized error is_custom 2');

is($o->error . '', 'doom', 'localized error 2');

$o->localizer->add_localized_message_text(name => 'DOOM', locale => 'jp', text => 'doom-san');
$o->locale('jp');
is($o->error . '', 'doom-san', 'localized error 4');

$o->locale('xx');
is($o->error . '', 'le doom', 'localized error 5');

#
# Localized errors and messages - invalid operations
#

# Messages

eval { $o->localizer->add_localized_message(name => 'MY_MSG', text => 'foo') };
ok($@ =~ /MY_MSG already exists/, 'localized message - name exists');

$id = $o->localizer->get_message_id('MY_MSG');
eval { $o->localizer->add_localized_message(id => $id, text => 'foo') };
ok($@ =~ /Missing name for new localized message/i, 'localized message - missing name');

eval { $o->localizer->add_localized_message(name => 'FOO') };
ok($@ =~ /Missing new localized message text/i, 'localized message - missing text');

# Errors

eval { $o->localizer->add_localized_error(name => 'MY_ERROR', text => 'foo') };
ok($@, 'localized error - name exists');

$id = $o->localizer->get_error_id('MY_ERROR');
eval { $o->localizer->add_localized_error(id => $id, text => 'foo') };
ok($@ =~ /Missing localized error name/i, 'localized error - missing name');

#
# Subclass with custom messages
#

eval 'require MyObject::BadMessages';
ok($@ =~ /a message with the id 2 already exists/, 'bad messages 1');

eval 'require MyObject::BadErrors';
ok($@ =~ /a message with the id 3 already exists/, 'bad errors 1');

use MyObject::Errors qw(:all);
use MyObject::Messages qw(:all);

is($MyObject::MYOBJ_MSG1, MYOBJ_MSG1, 'MyObject::MYOBJ_MSG1');
is($MyObject::MYOBJ_ERR1, MYOBJ_ERR1, 'MyObject::MYOBJ_ERR1');

BEGIN
{
  use MyObject2;

  BEGIN
  {
    MyObject2->localizer->import_message_ids('MYOBJ_MSG2');
    MyObject2->localizer->import_error_ids(':all');
  }

  is($MyObject2::MYOBJ_MSG2, MYOBJ_MSG2, 'MyObject2::MYOBJ_MSG2');
  is($MyObject2::MYOBJ_ERR2, MYOBJ_ERR2, 'MyObject2::MYOBJ_ERR2');
}

# MyObject

$o = MyObject->new;

$o->error_id(MYOBJ_ERR1, { a => 'A', b => 'B' });
is($o->error->as_string, 'This is my object msg 1: B, A', 'MYOBJ_ERR1 en');

$o->locale('xx');
is($o->error->as_string, "C'est mon object\nmsg 1: B, A", 'MYOBJ_ERR1 xx');

MyObject->localizer->locale_cascade(
{
  'en-us'   => [ 'en' ],
  'en-uk'   => [ 'en' ],
  'default' => [ 'en' ],
});

$o->locale('en-us');
is($o->error . '', 'This is my object msg 1: B, A', 'MYOBJ_ERR1 en-us');

# MyObject2

MyObject2->localizer->locale_cascade(
{
  'en-us'   => [ 'en' ],
  'en-uk'   => [ 'en' ],
  'default' => [ 'en' ],
});

$o = MyObject2->new;

$o->error_id('MYOBJ_ERR2', { a => 'A', b => 'B' });

is($o->error->as_string, 'my msg 2: B, A', 'MYOBJ_ERR2 en');

$o->locale('xx');
is($o->error->as_string, "mon\nmsg 2: B, A", 'MYOBJ_ERR2 xx');

$o->locale('en-us');

is($o->error . '', 'my msg 2: B, A', 'MYOBJ_ERR2 en-us');

$o->error_id(MYOBJ_ERR2, [ 'A','B' ]);
is($o->error->as_string, 'my msg 2: B, A', 'MYOBJ_ERR2 en 2');

$o->error_id(MYOBJ_ERR3(), { a => 'A', b => 'B' });
is($o->error->as_string, 'my msg 3: B, A', 'MYOBJ_ERR3 en');
$o->locale('xx');
is($o->error->as_string, "mon\nmsg 3: B, A", 'MYOBJ_ERR3 xx');

