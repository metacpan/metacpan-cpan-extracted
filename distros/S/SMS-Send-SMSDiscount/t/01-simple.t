#!/usr/bin/perl -w
#
# Copyright (C) 2011 by Mark Hindess

use strict;

BEGIN {
  require Test::More;
  eval { require LWP::Protocol::https };
  if ($@) {
    import Test::More skip_all => 'No LWP::Protocol::https module: $@';
  }
  eval { require LWP::Protocol::PSGI };
  if ($@) {
    import Test::More skip_all => 'No LWP::Protocol::PSGI module: $@';
  }
  eval { require SMS::Send };
  if ($@) {
    import Test::More skip_all => 'No SMS::Send module: $@';
  }
  eval { require Plack::Request };
  if ($@) {
    import Test::More skip_all => 'No Plack::Request module: $@';
  }
  import Test::More tests => 32;
}

use LWP::UserAgent;

my @resp =
  (
   [ 200,  [ 'Content-Type' => 'text/html' ],
     [qq{<?phpxml version="1.0" encoding="utf-8"?>\n},
      "<SmsResponse>\n",
      "  <version>1</version>\n",
      "  <result>1</result>\n",
      "  <resultstring>success</resultstring>\n",
      "  <description></description>\n",
      "  <endcause></endcause>\n",
      "</SmsResponse>\n",
     ] ],
   [ 200,  [ 'Content-Type' => 'text/html' ],
     [qq{<?phpxml version="1.0" encoding="utf-8"?>\n},
      "<SmsResponse>\n",
      "  <version>1</version>\n",
      "  <result>0</result>\n",
      "  <resultstring>failure</resultstring>\n",
      "  <description>Sorry, you do not have enough credit to send this sms. Go to your accountpage to buy credit!</description>\n",
      "<endcause>1</endcause>\n",
      "</SmsResponse>\n",
     ] ],
   [ 402,  [ 'Content-Type' => 'text/plain' ], ["Oops\n"] ],
   [ 200,  [ 'Content-Type' => 'text/plain' ], ["Oops\n"] ],
   [ 402,  [ 'Content-Type' => 'text/plain' ], ["Oops\n"] ],
  );
my $count = 1;
my $psgi_app =
  sub {
    my $env = shift; # PSGI env
    my $req = Plack::Request->new($env);
    my $p = $req->body_parameters;
    is($p->{username}, 'test', 'username - request '.$count);
    is($p->{password}, 'pass', 'password - request '.$count);
    is($p->{to}, '+441234654321', 'to - request '.$count);
    is($p->{text}, 'text'.$count, 'text - request '.$count);
    $count++;
    return shift @resp;
  };

LWP::Protocol::PSGI->register($psgi_app);

use_ok('SMS::Send::SMSDiscount');
my $sms = SMS::Send->new('SMSDiscount',
                         _login => 'test', _password => 'pass',
                         _verbose => 0);
ok($sms, 'SMS::Send->new with SMSDiscount driver');

ok($sms->send_sms(text => 'text1', to => '+441234654321'),
   'SMSDiscount successful message');
ok(!$sms->send_sms(text => 'text2', to => '+441234654321'),
   'SMSDiscount unsuccessful message');
ok(!$sms->send_sms(text => 'text3', to => '+441234654321'),
   'SMSDiscount HTTP error');

$sms = SMS::Send->new('SMSDiscount', _login => 'test', _password => 'pass');
ok($sms, 'SMS::Send->new with SMSDiscount driver - verbose');

my $res;
is(test_warn(sub {
               $res = $sms->send_sms(text => 'text4', to => '+441234654321'),
             }),
   "Failed: Oops\n",
   'SMSDiscount unsuccessful message warning');
ok(!$res, 'SMSDiscount unsuccessful message w/verbose mode');
like(test_warn(sub {
                 $sms->send_sms(text => 'text5', to => '+441234654321'),
               }),
     qr/^HTTP failure:.*402 Payment required/i,
     'SMSDiscount HTTP error warning');
ok(!$res, 'SMSDiscount HTTP error w/verbose mode');

is(test_error(sub { SMS::Send->new('SMSDiscount') }),
   "SMS::Send::SMSDiscount->new requires _login parameter\n",
   'requires _login parameter');
is(test_error(sub { SMS::Send->new('SMSDiscount', _login => 'test') }),
   "SMS::Send::SMSDiscount->new requires _password parameter\n",
   'requires _password parameter');

=head2 C<test_error($code_ref)>

This method runs the code with eval and returns the error.  It strips
off some common strings from the end of the message including any "at
<file> line <number>" strings and any "(@INC contains: .*)".

=cut

sub test_error {
  my $sub = shift;
  eval { $sub->() };
  my $error = $@;
  if ($error) {
    $error =~ s/\s+at (\S+|\(eval \d+\)(\[[^]]+\])?) line \d+\.?\s*$//g;
    $error =~ s/\s+at (\S+|\(eval \d+\)(\[[^]]+\])?) line \d+\.?\s*$//g;
    $error =~ s/ \(\@INC contains:.*?\)$//;
  }
  return $error;
}

=head2 C<test_warn($code_ref)>

This method runs the code with eval and returns the warning.  It strips
off any "at <file> line <number>" specific part(s) from the end.

=cut

sub test_warn {
  my $sub = shift;
  my $warn;
  local $SIG{__WARN__} = sub { $warn .= $_[0]; };
  eval { $sub->(); };
  die $@ if ($@);
  if ($warn) {
    $warn =~ s/\s+at (\S+|\(eval \d+\)(\[[^]]+\])?) line \d+\.?\s*$//g;
    $warn =~ s/\s+at (\S+|\(eval \d+\)(\[[^]]+\])?) line \d+\.?\s*$//g;
    $warn =~ s/ \(\@INC contains:.*?\)$//;
  }
  return $warn;
}
