#!/usr/bin/perl -w

use strict;

use Test::More tests => 20;

use Rose::HTML::Object::Messages qw(:field FORM_HAS_ERRORS);

is(FIELD_REQUIRED_GENERIC, Rose::HTML::Object::Messages::FIELD_REQUIRED_GENERIC(), 'import 1');
is(FIELD_PARTIAL_VALUE, Rose::HTML::Object::Messages::FIELD_PARTIAL_VALUE(), 'import 2');
is(FORM_HAS_ERRORS, Rose::HTML::Object::Messages::FORM_HAS_ERRORS(), 'import 3');

my $messages = Rose::HTML::Object::Messages->message_ids;
is(scalar @$messages, 45, 'message_ids 1');

my @messages = Rose::HTML::Object::Messages->message_ids;
is(scalar @messages, 45, 'message_ids 2');

ok(Rose::HTML::Object::Messages->message_id_exists(FIELD_REQUIRED_GENERIC), 'message_id_exists 1');
ok(!Rose::HTML::Object::Messages->message_id_exists(-12345), 'message_id_exists 2');

ok(Rose::HTML::Object::Messages->message_name_exists('FIELD_REQUIRED_GENERIC'), 'message_name_exists 1');
ok(!Rose::HTML::Object::Messages->message_name_exists('NONESUCH'), 'message_name_exists 2');

is(Rose::HTML::Object::Messages->get_message_id('FIELD_REQUIRED_GENERIC'), FIELD_REQUIRED_GENERIC, 'get_message_id 1');
is(Rose::HTML::Object::Messages->get_message_id('NONESUCH'), undef, 'get_message_id 2');

is(Rose::HTML::Object::Messages->get_message_name(FIELD_REQUIRED_GENERIC), 'FIELD_REQUIRED_GENERIC', 'get_message_name 1');
is(Rose::HTML::Object::Messages->get_message_name(-12345), undef, 'get_messageget_message_name_id 2');

Rose::HTML::Object::Messages->add_message(TEST_MESSAGE => 30_000);

is(Rose::HTML::Object::Messages->get_message_id('TEST_MESSAGE'), 30_000, 'add_message 1');
is(Rose::HTML::Object::Messages->get_message_name(30_000), 'TEST_MESSAGE', 'add_message 2');

Rose::HTML::Object::Messages->import('TEST_MESSAGE');
eval "is(TEST_MESSAGE, 30_000, 'import new constant 1');";
die $@  if($@);

package Rose::HTML::Object::Messages;

use constant TEST_MESSAGE2 => 30_002;
use constant TEST_MESSAGE3 => 30_003;

package main;

Rose::HTML::Object::Messages->add_messages(qw(TEST_MESSAGE2 TEST_MESSAGE3));

Rose::HTML::Object::Messages->import(qw(TEST_MESSAGE2 TEST_MESSAGE3));
eval "is(TEST_MESSAGE2, 30_002, 'import new constant 2');";
die $@  if($@);
eval "is(TEST_MESSAGE3, 30_003, 'import new constant 3');";
die $@  if($@);

my $list = join(',', sort { $a <=> $b } 
  qw(-1 1 2 4 5 6 7 8 10 11 100 1300 1301 1302 1303 1304 1305 1306 1307
     1400 1500 1501 1550 1551 1552 1553 1554 1600 1650 1700 1701 10000 10001
     10002 10003 10004 10005 11000 11001 11002 11003 11004 11005 11006 11007
     30000 30002 30003));

is(join(',', sort { $a <=> $b } Rose::HTML::Object::Messages->message_ids), $list, 'message_ids');

$list = join(',', sort
  qw(CUSTOM_MESSAGE DATE_INVALID DATE_MIN_GREATER_THAN_MAX EMAIL_INVALID
     FIELD_DESCRIPTION FIELD_ERROR_LABEL_DAY FIELD_ERROR_LABEL_HOUR
     FIELD_ERROR_LABEL_MAXIMUM_DATE FIELD_ERROR_LABEL_MINIMUM_DATE
     FIELD_ERROR_LABEL_MINUTE FIELD_ERROR_LABEL_MONTH FIELD_ERROR_LABEL_SECOND
     FIELD_ERROR_LABEL_YEAR FIELD_INVALID_GENERIC FIELD_INVALID_LABELLED
     FIELD_LABEL FIELD_LABEL_DAY FIELD_LABEL_HOUR FIELD_LABEL_MINUTE
     FIELD_LABEL_MONTH FIELD_LABEL_SECOND FIELD_LABEL_YEAR FIELD_PARTIAL_VALUE
     FIELD_REQUIRED_GENERIC FIELD_REQUIRED_LABELLED FIELD_REQUIRED_SUBFIELD
     FIELD_REQUIRED_SUBFIELDS FORM_HAS_ERRORS NUM_ABOVE_MAX NUM_BELOW_MIN
     NUM_INVALID_INTEGER NUM_INVALID_INTEGER_POSITIVE NUM_INVALID_NUMBER
     NUM_INVALID_NUMBER_POSITIVE NUM_NOT_POSITIVE_INTEGER
     NUM_NOT_POSITIVE_NUMBER PHONE_INVALID SET_INVALID_QUOTED_STRING
     SET_PARSE_ERROR STRING_OVERFLOW TEST_MESSAGE TEST_MESSAGE2
     TEST_MESSAGE3 TIME_INVALID TIME_INVALID_AMPM TIME_INVALID_HOUR
     TIME_INVALID_MINUTE TIME_INVALID_SECONDS));

is(join(',', sort Rose::HTML::Object::Messages->message_names), $list, 'message_names');
