# --perl--
use strict;
use warnings;
use JSON qw{encode_json};

use Test::More tests => 42;
BEGIN { use_ok('SMS::Send::Adapter::Node::Red') };
BEGIN { use_ok('SMS::Send') };
BEGIN { use_ok('SMS::Send::VoIP::MS') };

{
  my $self = SMS::Send::Adapter::Node::Red->new;
  can_ok($self, 'new');
  can_ok($self, 'content');
  can_ok($self, 'cgi_response');
  can_ok($self, 'psgi_app');
  can_ok($self, 'CGI');
  can_ok($self, 'SMS');
  can_ok($self, 'send_sms');
  can_ok($self, 'set_status_error');
  can_ok($self, 'error');
  can_ok($self, 'input');
  can_ok($self, 'status');
  can_ok($self, 'status_string');
}

{
  my $self = SMS::Send::Adapter::Node::Red->new(content=>"");
  isa_ok($self, 'SMS::Send::Adapter::Node::Red');

  is($self->input, undef);
  is($self->status, '400');
  is($self->status_string, '400 Bad Request');
  is($self->error, 'Error: JSON decode failed');
}

{
  my $self = SMS::Send::Adapter::Node::Red->new(content=>"[]");
  isa_ok($self, 'SMS::Send::Adapter::Node::Red');

  is($self->input, undef);
  is($self->status, '400');
  is($self->status_string, '400 Bad Request');
  is($self->error, 'Error: JSON Object required');
}

{
  my $content = encode_json({to=>'my_to', text=>"my_text", driver=>'my_driver'});

  my $self = SMS::Send::Adapter::Node::Red->new(content=>$content);
  isa_ok($self, 'SMS::Send::Adapter::Node::Red');

  ok(defined($self->input));
  isa_ok($self->input, 'HASH');
  is($self->input->{'to'}    , 'my_to');
  is($self->input->{'text'}  , 'my_text');
  is($self->input->{'driver'}, 'my_driver');

  ok(!$self->SMS, 'SMS when bad driver');
  is($self->status, '500');
  is($self->status_string, '500 Internal Server Error');
  like($self->error, qr/\AFailed to load/);
}

{
  my $content = encode_json({driver=>'VoIP::MS'});

  my $self = SMS::Send::Adapter::Node::Red->new(content=>$content);
  isa_ok($self, 'SMS::Send::Adapter::Node::Red');

  ok(defined($self->input));
  isa_ok($self->input, 'HASH');
  is($self->input->{'driver'}, 'VoIP::MS');

  isa_ok($self->SMS, 'SMS::Send', 'SMS when good driver');
  ok(!$self->error);
}

{
  my $app = SMS::Send::Adapter::Node::Red->psgi_app;
  isa_ok($app, 'CODE');
}
