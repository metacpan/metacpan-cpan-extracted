# ============
# bulksms.t
# ============
package _Mock::Message;
use Mojo::Base -base;
has 'body';

package main;
use Mojo::Base -strict;
use Mojar::Message::BulkSms;

package Mojar::Message::BulkSms;
no warnings 'redefine';
$Mojar::Message::BulkSms::response = [0, 'IN_PROGRESS'];

sub submit {
  my ($self, $location, $cb) = @_;
  my $error;
  @$error{'code', 'message'} = @{$Mojar::Message::BulkSms::response};
  return $self->handle_error($error, $cb) if $error->{code};
  return $cb ? $cb->($self) : $self;
}

package main;
use Test::More;

# Disable IPv6 and libev
BEGIN {
  $ENV{MOJO_MODE}    = 'testing';
  $ENV{MOJO_NO_IPV6} = 1;
  $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll';
}

use Mojar::Util 'dumper';

my $sms;

subtest q{Basic} => sub {
  ok $sms = Mojar::Message::BulkSms->new(
    username => 'some_user',
    password => 'some_pissword'
  );
};

subtest q{Parameters} => sub {
  my $e;
  ok ! $sms->send(sub {$e = $_[1]; $e ? undef : $_[0]}), 'return code';
  ok $e, 'called back error';
  ok $e->{message} =~ /Missing parameters/, 'identified problem';
  ok $e->{message} =~ /recipient/, 'highlighted recipient';
  ok $e->{message} =~ /message/, 'highlighted message';

  undef $e;
  ok ! $sms->recipient('0044 78-23 12 99')->send(
      sub {$e = $_[1]; $e ? undef : $_[0]}), 'return code';
  ok $e->{message} =~ /Missing parameters/, 'identified problem again';
  ok $e->{message} !~ /recipient/, 'has recipient';

  undef $e;
  ok $sms->message(' Some text ')->send(sub {$e = $_[1]; $_[0] unless $e}),
      'return code';
  ok ! $e, 'no exception' or diag $e;
  is $sms->recipient, '4478231299', 'recipient cleansed';
  is $sms->message, 'Some text', 'message trimmed';

  ok $sms->send(message => 'Other text '), 'success';
  is $sms->recipient, '4478231299', 'recipient intact';
  is $sms->message, 'Other text', 'message changed';

  ok $sms->send(recipient => q{+44 781 2676 398}), 'send ok';
  is $sms->recipient, '447812676398', 'recipient cleansed';
  is $sms->message, 'Other text', 'message intact';

  ok $sms->international_prefix('33'), 'set prefix';
  ok $sms->send(recipient => q{0781 2676 398}), 'send ok';
  is $sms->recipient, '337812676398', 'recipient cleansed';

  ok $sms->send, 'repeat sending with cached details';
};

subtest q{Chaining} => sub {
  ok $sms->send(message => q{We're back on the chain gang!})
      ->send(recipient => '07768 321 123')
      ->send(recipient => '07768 123 321');
};

subtest q{Response} => sub {
  $Mojar::Message::BulkSms::response =
      [23, 'invalid credentials (username was: mud)'];
  my $e;
  ok ! $sms->send(sub {$e = $_[1]; $e ? undef : $_[0]}), 'return code';
  ok $e, 'called back error';
  is $e->{code}, 23, 'identified code';
  ok $e->{message} =~ /invalid credentials/, 'identified problem'
    or diag 'Actual message was: '. $e->{message};

  $Mojar::Message::BulkSms::response =
      [24, 'invalid msisdn: 44'];
  undef $e;
  ok ! $sms->send(sub {$e = $_[1]; $e ? undef : $_[0]}), 'return code';
  ok $e, 'called back error';
  is $e->{code}, 24, 'identified code';
  ok $e->{message} =~ /invalid msisdn/, 'identified problem'
    or diag 'Actual message was: '. $e->{message};
};

done_testing();
