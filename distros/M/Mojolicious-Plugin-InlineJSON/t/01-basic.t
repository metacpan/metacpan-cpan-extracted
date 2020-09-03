use Test::More;
use Mojolicious::Plugin::InlineJSON;

my $test = Mojolicious::Plugin::InlineJSON->new;

subtest 'Basic' => sub {
  is $test->js_data({ foo => 'bar' }),
    '{"foo":"bar"}', 'basic thing works';

  is $test->js_json_string({ foo => 'bar' }),
    '"{\"foo\":\"bar\"}"', 'the string one works';

  is $test->js_data_via_json({ foo => 'bar' }),
    'JSON.parse("{\"foo\":\"bar\"}")', 'json.parse works';
};

subtest 'escaping a tag' => sub {
  is $test->js_data({ foo => 'bar>' }),
    '{"foo":"bar\>"}', 'basic thing works';
  is $test->js_json_string({ foo => 'bar>' }),
    '"{\"foo\":\"bar\>\"}"', 'the string one works';
};

done_testing;
