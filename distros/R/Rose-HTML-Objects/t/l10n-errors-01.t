#!/usr/bin/perl -w

use strict;

use Test::More tests => 20;

use Rose::HTML::Object::Errors qw(:field FORM_HAS_ERRORS);

is(FIELD_REQUIRED, Rose::HTML::Object::Errors::FIELD_REQUIRED(), 'import 1');
is(FIELD_PARTIAL_VALUE, Rose::HTML::Object::Errors::FIELD_PARTIAL_VALUE(), 'import 2');
is(FORM_HAS_ERRORS, Rose::HTML::Object::Errors::FORM_HAS_ERRORS(), 'import 3');

my $errors = Rose::HTML::Object::Errors->error_ids;
is(scalar @$errors, 25, 'error_ids 1');

my @errors = Rose::HTML::Object::Errors->error_ids;
is(scalar @errors, 25, 'error_ids 2');

ok(Rose::HTML::Object::Errors->error_id_exists(FIELD_REQUIRED), 'error_id_exists 1');
ok(!Rose::HTML::Object::Errors->error_id_exists(-12345), 'error_id_exists 2');

ok(Rose::HTML::Object::Errors->error_name_exists('FIELD_REQUIRED'), 'error_name_exists 1');
ok(!Rose::HTML::Object::Errors->error_name_exists('NONESUCH'), 'error_name_exists 2');

is(Rose::HTML::Object::Errors->get_error_id('FIELD_REQUIRED'), FIELD_REQUIRED, 'get_error_id 1');
is(Rose::HTML::Object::Errors->get_error_id('NONESUCH'), undef, 'get_error_id 2');

is(Rose::HTML::Object::Errors->get_error_name(FIELD_REQUIRED), 'FIELD_REQUIRED', 'get_error_name 1');
is(Rose::HTML::Object::Errors->get_error_name(-12345), undef, 'get_errorget_error_name_id 2');

Rose::HTML::Object::Errors->add_error(TEST_ERROR => 30_000);

is(Rose::HTML::Object::Errors->get_error_id('TEST_ERROR'), 30_000, 'add_error 1');
is(Rose::HTML::Object::Errors->get_error_name(30_000), 'TEST_ERROR', 'add_error 2');

Rose::HTML::Object::Errors->import('TEST_ERROR');
eval "is(TEST_ERROR, 30_000, 'import new constant 1');";
die $@  if($@);

package Rose::HTML::Object::Errors;

use constant TEST_ERROR2 => 30_002;
use constant TEST_ERROR3 => 30_003;

package main;

Rose::HTML::Object::Errors->add_errors(qw(TEST_ERROR2 TEST_ERROR3));

Rose::HTML::Object::Errors->import(qw(TEST_ERROR2 TEST_ERROR3));
eval "is(TEST_ERROR2, 30_002, 'import new constant 2');";
die $@  if($@);
eval "is(TEST_ERROR3, 30_003, 'import new constant 3');";
die $@  if($@);

my $list = join(',', sort { $a <=> $b } 
  qw(-1 3 8 9 100 1300 1301 1302 1303 1304 1305 1306 1307 1400 1500 1501
     1550 1551 1552 1553 1554 1600 1650 1700 1701 30000 30002 30003));

is(join(',', sort { $a <=> $b } Rose::HTML::Object::Errors->error_ids), $list, 'error_ids');

$list = join(',', sort
  qw(CUSTOM_ERROR DATE_INVALID DATE_MIN_GREATER_THAN_MAX EMAIL_INVALID
     FIELD_INVALID FIELD_PARTIAL_VALUE FIELD_REQUIRED FORM_HAS_ERRORS
     NUM_ABOVE_MAX NUM_BELOW_MIN NUM_INVALID_INTEGER
     NUM_INVALID_INTEGER_POSITIVE NUM_INVALID_NUMBER
     NUM_INVALID_NUMBER_POSITIVE NUM_NOT_POSITIVE_INTEGER
     NUM_NOT_POSITIVE_NUMBER PHONE_INVALID SET_INVALID_QUOTED_STRING
     SET_PARSE_ERROR STRING_OVERFLOW TEST_ERROR TEST_ERROR2 TEST_ERROR3
     TIME_INVALID TIME_INVALID_AMPM TIME_INVALID_HOUR TIME_INVALID_MINUTE
     TIME_INVALID_SECONDS));

is(join(',', sort Rose::HTML::Object::Errors->error_names), $list, 'error_names');
