#!--perl--
use strict;
use warnings;
use Path::Class qw{file dir};
use Test::More tests => 28;

BEGIN { use_ok('SMS::Send') };
BEGIN { use_ok('SMS::Send::VoIP::MS') };

{
  my $obj = SMS::Send->new('VoIP::MS', _did=>'8005551234', _username=>'u', _password=>'p');
  isa_ok($obj, 'SMS::Send');
  is($obj->username, 'u', 'username');
  is($obj->password, 'p', 'password');
  is($obj->did, '8005551234', 'did');
}

{
  my $ini = file(file($0)->dir => 'test.ini');
  my $obj = SMS::Send::VoIP::MS->new(cfg_file=>"$ini");
  isa_ok($obj, 'SMS::Send::VoIP::MS');

  can_ok($obj, 'new');
  can_ok($obj, 'username');
  can_ok($obj, 'password');
  can_ok($obj, 'url');
  can_ok($obj, 'did');
  can_ok($obj, 'send_sms');
  is($obj->url, 'https://voip.ms/api/v1/rest.php', 'url');
  is($obj->username, 'myuser', 'username');
  is($obj->password, 'mypass', 'password');
  is($obj->did, '8005551212', 'did');
}

{
  my $ini = file(file($0)->dir => 'empty.ini');
  my $obj = SMS::Send::VoIP::MS->new(cfg_file=>"$ini");
  isa_ok($obj, 'SMS::Send::VoIP::MS');

  can_ok($obj, 'new');
  can_ok($obj, 'username');
  can_ok($obj, 'password');
  can_ok($obj, 'url');
  can_ok($obj, 'did');
  can_ok($obj, 'send_sms');
  is($obj->url, 'https://voip.ms/api/v1/rest.php', 'url');
  {
    local $@;
    eval{$obj->username};
    my $error = $@;
    like($error, qr/Error: username property required/, 'username required');
  }
  {
    local $@;
    eval{$obj->password};
    my $error = $@;
    like($error, qr/Error: password property required/, 'password required');
  }
  {
    local $@;
    eval{$obj->did};
    my $error = $@;
    like($error, qr/Error: property did required/, 'did required');
  }
}
