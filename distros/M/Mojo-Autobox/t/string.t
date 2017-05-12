use Mojo::Base -strict;

use Mojo::Autobox;

use Test::More;

subtest 'byte_stream method' => sub {
  my $b = '  hello world  '->byte_stream;
  isa_ok $b, 'Mojo::ByteStream', 'right type';
  is $b->trim, 'hello world', 'right ByteStream behavior';
};

subtest 'b method' => sub {
  my $b = '  hello world  '->b;
  isa_ok $b, 'Mojo::ByteStream', 'right type';
  is $b->trim, 'hello world', 'right ByteStream behavior';
};

subtest 'dom method' => sub {
  my $dom = '<a href="http://somesite.com">Doit</a>'->dom;
  isa_ok $dom, 'Mojo::DOM', 'right type';
  is $dom->at('a')->text, 'Doit', 'right DOM behavior';
  is $dom->at('a')->{href}->url->host, 'somesite.com', 'chained with url method';

  my $coll = '<a href="http://somesite.com">Doit</a>'->dom('a');
  isa_ok $coll, 'Mojo::Collection', 'argument is passed to find';
  is @$coll, 1, 'one record is found';
};

subtest 'json method' => sub {
  my $json = '{"key": {"deeper": "value"}}';
  is_deeply $json->json, {key => {deeper => 'value'}}, 'right structure';
  is $json->json('/key/deeper'), 'value', 'pointer value';
};

subtest 'j method' => sub {
  my $json = '{"key": {"deeper": "value"}}';
  is_deeply $json->j, {key => {deeper => 'value'}}, 'right structure';
  is $json->j('/key/deeper'), 'value', 'pointer value';
};

subtest 'url method' => sub {
  my $url = 'http://mysite.com/path#anchor'->url;
  isa_ok $url, 'Mojo::URL', 'right type';
  is $url->path, '/path', 'right path';
  is $url->fragment, 'anchor', 'right fragment';
};

done_testing;

