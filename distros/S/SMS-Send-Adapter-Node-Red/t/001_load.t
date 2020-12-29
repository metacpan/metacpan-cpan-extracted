use strict;
use warnings;
use JSON qw{encode_json};

use Test::More tests => 13;
BEGIN { use_ok('SMS::Send::Adapter::Node::Red') };
BEGIN { use_ok('SMS::Send') };
BEGIN { use_ok('SMS::Send::VoIP::MS') };

{
  my $content = encode_json({to=>'my_to', text=>"my_text", driver=>'my_driver'});

  my $self = SMS::Send::Adapter::Node::Red->new(content=>$content);
  isa_ok($self, 'SMS::Send::Adapter::Node::Red');

  isa_ok($self->input, 'HASH');
  is($self->input->{'to'}    , 'my_to');
  is($self->input->{'text'}  , 'my_text');
  is($self->input->{'driver'}, 'my_driver');

  ok(!$self->SMS, 'SMS when bad driver');
}

{
  my $content = encode_json({driver=>'VoIP::MS'});

  my $self = SMS::Send::Adapter::Node::Red->new(content=>$content);
  isa_ok($self, 'SMS::Send::Adapter::Node::Red');

  isa_ok($self->input, 'HASH');
  is($self->input->{'driver'}, 'VoIP::MS');

  isa_ok($self->SMS, 'SMS::Send', 'SMS when good driver');
}
