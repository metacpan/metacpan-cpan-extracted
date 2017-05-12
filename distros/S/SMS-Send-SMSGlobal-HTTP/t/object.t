#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 15;
use Test::NoWarnings;
use Test::Fatal;
use Test::MockObject;

use SMS::Send::SMSGlobal::HTTP;

my $mock_ua = Test::MockObject->new;
$mock_ua->mock( howdy => sub {'hello'} );

my $obj;
is( exception {
    $obj = SMS::Send::SMSGlobal::HTTP->new(
	_user      => 'my-username',
	_password  => 'my-password',
	__verbose =>  1,
	__ua => $mock_ua,
	);
	  } => undef,
	  "SMS::Send::SMSGlobal::HTTP->new(...) - lives"
    );

isa_ok( $obj => "SMS::Send::SMSGlobal::HTTP");
die "can't continue without object" unless $obj;

can_ok($obj => qw(send_sms action text to _user _password _from _maxsplit
                  _scheduledatetime _api _userfield __transport __verbose
                  __ua __address));

is(exception {$obj->{text} = 'sample message'} => undef, 'setting via hash - lives');
is($obj->text, 'sample message', '$obj->att accessor');
is($obj->get('text'), 'sample message', '$obj->get("att") accessor');

is(exception {$obj->text('message 2')} => undef, '$obj->att($val) setter - lives');
is($obj->text, 'message 2', '$obj->att($val) setter - result');

is(exception {$obj->set(text => 'message 3')} => undef, '$obj->set("att" => $val) setter - lives');
is($obj->text, 'message 3', '$obj->set("att" => $val) setter - result');

is($obj->__ua->howdy, 'hello', '$object->__ua from constructor');

isnt(exception {$obj->crud} => undef, '$obj->unknown_att - dies' );
isnt(exception {$obj->{crud} = "shouldn't work"} => undef, '$obj->{unknown_att} = $val - dies' );
isnt(exception {$obj->set(crud => "shouldn't work either")} => undef, '$obj->set("unknown_att => $val) - dies');

1;

