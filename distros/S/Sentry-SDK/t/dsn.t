use Mojo::Base -strict;

use Test::Spec;
use Sentry::DSN;

describe 'Sentry' => sub {
  my $dsn;

  before each => sub {
    $dsn = Sentry::DSN->parse(
      'http://ff21cbe6ddaf4314833eabd2075e38e3@localhost:9000/foo/bar/2');
  };

  it 'protocol' => sub {
    is($dsn->protocol, 'http');
  };

  it 'user' => sub {
    is($dsn->user, 'ff21cbe6ddaf4314833eabd2075e38e3');
  };

  it 'pass' => sub {
    is($dsn->pass, undef);
  };

  it 'host' => sub {
    is($dsn->host, 'localhost');
  };

  it 'port' => sub {
    is($dsn->port, '9000');
  };

  it 'path' => sub {
    is($dsn->path, '/foo/bar');

    $dsn = Sentry::DSN->parse('http://abc@localhost:9000/2');
    is($dsn->path, '');
  };

  it 'project_id' => sub {
    is($dsn->project_id, '2');
  };
};

runtests;
