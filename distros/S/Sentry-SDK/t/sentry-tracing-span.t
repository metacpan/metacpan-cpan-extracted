use Mojo::Base -strict, -signatures;

use Mojo::Util 'dumper';
use Sentry::Tracing::Span;
use Sentry::Tracing::Transaction;
use Test::More;
use Test::Spec;

describe 'Sentry::Tracing::Span' => sub {
  my $span;

  before each => sub {
    $span = Sentry::Tracing::Span->new({
      transaction =>
        Sentry::Tracing::Transaction->new(name => 'my transaction'),
    });
  };

  describe 'start_child()' => sub {
    my $child_span;

    before each => sub {
      $span->start_child({
        op => 'sql.query', description => 'SELECT * FROM foo' });

      $child_span = $span->spans->[0];
    };

    it 'adds a child span' => sub {
      is scalar $span->spans->@*, 1;
      isa_ok $span->spans->[0], 'Sentry::Tracing::Span';
    };

    it 'sets the op' => sub {
      is $child_span->op, 'sql.query';
    };

    it 'sets the description' => sub {
      is $child_span->description, 'SELECT * FROM foo';
    };

    it 'sets the transaction to parents transaction' => sub {
      ok defined $child_span->transaction;
      is $child_span->transaction->name, 'my transaction';
    };
  };

  it 'set_tag()' => sub {
    $span->set_tag('foo' => 'bar');
    $span->set_tag('bar' => 'baz');
    is_deeply $span->tags, { foo => 'bar', bar => 'baz' };
  };

  it 'set_http_status()' => sub {
    $span->set_http_status(200);
    is $span->status => 'ok';
  };

  it 'finish()' => sub {
    ok !defined $span->timestamp;
    $span->finish();
    ok defined $span->timestamp;
  };
};

runtests;
