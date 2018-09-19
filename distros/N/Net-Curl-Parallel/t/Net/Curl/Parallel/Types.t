use Test2::V0;
use Test2::API qw(context);
use Test2::Tools::Spec;
use Test2::Tools::Explain;
use Test2::Plugin::SpecDeclare;
use strictures 2;

use HTTP::Request;
use Net::Curl::Parallel::Types -all;
use URI::Fast qw(uri);

subtest Positive => sub{
  ok is_Positive(1),   'positive';
  ok !is_Positive(0),  'zero';
  ok !is_Positive(-1), 'negative';
};

subtest Natural => sub{
  ok is_Natural(1),   'positive';
  ok is_Natural(0),   'zero';
  ok !is_Natural(-1), 'negative';
};

subtest Agent => sub{
  ok is_Agent('Net::Curl::Parallel/v0.1'),  'basic';
  ok !is_Agent('Net::Curl::Parallel/0.1'),  'missing v';
  ok !is_Agent('Net::Curl::Parallel v0.1'), 'missing /';
  ok !is_Agent('Net::Curl::Parallel'),      'missing version';
  ok !is_Agent('/v0.1'),          'missing ident';
  ok !is_Agent(''),               'just missing';
};

subtest Headers => sub{
  ok is_Headers(['Foo: bar', 'Baz: bat']), 'ArrayRef[Str]';

  subtest coercions => sub{
    subtest Undef => sub{
      ok my $h = to_Headers(undef), 'coerce';
      is $h, [], 'result';
      ok is_Headers($h), 'validates';
    };

    subtest Array_of_Tuples => sub{
      ok my $h = to_Headers([['Foo', 'bar']]), 'coerce';
      is $h, ['Foo: bar'], 'result';
      ok is_Headers($h), 'validates';
    };

    subtest HashRef => sub{
      ok my $h = to_Headers({Foo => 'bar'}), 'coerce';
      is $h, ['Foo: bar'], 'result';
      ok is_Headers($h), 'validates';
    };

    subtest 'HTTP::Headers' => sub{
      my $instance = HTTP::Headers->new;
      $instance->header('Foo', 'bar');
      ok my $h = to_Headers($instance), 'coerce';
      is $h, ['Foo: bar'], 'result';
      ok is_Headers($h), 'validates';
    };
  };
};

subtest Content => sub{
  ok is_Content(undef), 'Maybe';
  ok is_Content('some data about stuff'), 'non-reserved chars';

  subtest coercions => sub{
    subtest 'HashRef' => sub{
      subtest 'simple' => sub{
        ok my $c = to_Content({foo => 'bar bat'}), 'coerce';
        my $uri = uri("?$c");
        is $uri->param('foo'), 'bar bat', 'result';
        ok is_Content($c), 'validates';
      };

      subtest 'multiple keys' => sub{
        ok my $c = to_Content({foo => ['bar', 'bat']}), 'coerce';
        my $uri = uri("?$c");
        is [$uri->param('foo')], ['bar', 'bat'], 'result';
        ok is_Content($c), 'validates';
      };
    };

    subtest 'ArrayRef[Tuple[Str, Str]]' => sub{
      subtest 'simple' => sub{
        ok my $c = to_Content([[foo => 'bar bat']]), 'coerce';
        my $uri = uri("?$c");
        is $uri->param('foo'), 'bar bat', 'result';
        ok is_Content($c), 'validates';
      };

      subtest 'multiple keys' => sub{
        ok my $c = to_Content([['foo', 'bar'], ['foo', 'bat']]), 'coerce';
        my $uri = uri("?$c");
        is [$uri->param('foo')], ['bar', 'bat'], 'result';
        ok is_Content($c), 'validates';
      };
    };
  };
};

subtest Uri => sub{
  ok is_Uri('https://www.example.com'), 'valid uri';
  ok !is_Uri('http://'), 'missing host name';
  ok !is_Uri(''), 'empty string';
  ok !is_Uri('?foo=bar'), 'query string w/o host name';
};

subtest Request => sub{
  ok is_Request(['GET', 'http://www.example.com', ['Foo: bar'], 'some data about things']), 'basic';
  ok !is_Request('http://www.example.com'), 'uri';

  subtest coercions => sub{
    subtest 'HTTP::Request' => sub{
      my $req = HTTP::Request->new(GET => 'http://www.example.com');
      ok my $r = to_Request($req), 'coerce';
      is $r, ['GET', 'http://www.example.com', [], undef], 'result';
      ok is_Request($r), 'validates' or diag Dumper(Request->validate_explain($r));
    };

    subtest 'ArrayRef' => sub{
      ok my $r = to_Request(['GET', 'http://www.example.com', 'Foo: bar']), 'coerce';
      is $r, ['GET', 'http://www.example.com', ['Foo: bar'], undef], 'result';
      ok is_Request($r), 'validates' or diag Dumper(Request->validate_explain($r));
    };

    subtest 'ArrayRef[ArrayRef] headers' => sub{
      ok my $r = to_Request(['GET', 'http://www.example.com', [['Foo', 'bar']]]), 'coerce';
      is $r, ['GET', 'http://www.example.com', ['Foo: bar'], undef], 'result';
      ok is_Request($r), 'validates' or diag Dumper(Request->validate_explain($r));
    };

    subtest 'HashRef headers' => sub{
      ok my $r = to_Request(['GET', 'http://www.example.com', {'Foo' => 'bar'}]), 'coerce';
      is $r, ['GET', 'http://www.example.com', ['Foo: bar'], undef], 'result';
      ok is_Request($r), 'validates' or diag Dumper(Request->validate_explain($r));
    };
  };
};

done_testing;
