use Mojo::Base -strict, -signatures;

use Mojo::File;
# curfile missing in Mojolicious@^8. The dependency shall not be updated for
# the time being. For this reason `curfile` is duplicated for now.
# use lib curfile->sibling('lib')->to_string;
# See https://github.com/mojolicious/mojo/blob/4093223cae00eb516e38f2226749d2963597cca3/lib/Mojo/File.pm#L36
use lib Mojo::File->new(Cwd::realpath((caller)[1]))->sibling('lib')->to_string;

use Mock::Sentry::Client;
use Mojo::Exception;
use Mojo::Util 'dumper';
use Sentry::Hub;
use Sentry::Logger 'logger';
use Sentry::SDK;
use Sentry::Severity;
use Test::Snapshot;
use Test::Spec;
use UUID::Tiny 'is_UUID_string';
use version;

describe 'Sentry::SDK' => sub {
  my $hub;

  before each => sub {
    $hub = Sentry::Hub->get_current_hub();
    $hub->reset();
  };

  it 'has a $VERSION' => sub {
    isa_ok $Sentry::SDK::VERSION => 'version';
  };

  describe 'init()' => sub {
    before each => sub {
      $Sentry::SDK::VERSION = version->declare('v1.1.1');

      Sentry::SDK->init({
        release            => 'my release',
        dsn                => 'abc',
        traces_sample_rate => 0.5,
        environment        => 'my env',
        debug              => 1,
      });
    };

    it 'creates a client' => sub {
      isa_ok $hub->client, 'Sentry::Client';
    };

    it 'passes options to the client' => sub {
      is_deeply_snapshot($hub->client->get_options, 'client options');
    };

    it 'sets the logger context' => sub {
      is_deeply(logger->active_contexts, ['.*']);
    };

    it 'reads options from ENV' => sub {
      local $ENV{SENTRY_DSN}                = 'DSN from env';
      local $ENV{SENTRY_RELEASE}            = 'release from env';
      local $ENV{SENTRY_TRACES_SAMPLE_RATE} = '0.123';
      local $ENV{SENTRY_ENVIRONMENT}        = 'environment from env';

      Sentry::SDK->init();

      is_deeply_snapshot($hub->client->get_options, 'client options (env)');
    };
  };

  describe 'message sending' => sub {
    my $client;

    before each => sub {
      $client = Mock::Sentry::Client->new;
      $hub->client($client);
    };

    it 'capture_message()' => sub {
      Sentry::SDK->capture_message('foo', Sentry::Severity->Warning);

      my $captured = $client->_captured_message;
      is $captured->{level}   => 'warning';
      is $captured->{message} => 'foo';
      isa_ok $captured->{scope}, 'Sentry::Hub::Scope';
      is_UUID_string $captured->{hint}{event_id};
    };

    it 'capture_event()' => sub {
      my $event = { foo => 'bar' };
      Sentry::SDK->capture_event($event);

      my $captured = $client->_captured_message;
      isa_ok $captured->{scope},    'Sentry::Hub::Scope';
      is_deeply $captured->{event}, $event;
      is_UUID_string $captured->{hint}{event_id};
    };

    it 'capture_exception()' => sub {
      my $exception = Mojo::Exception->new('ohoh');
      Sentry::SDK->capture_exception($exception);

      my $captured = $client->_captured_message;
      isa_ok $captured->{scope}, 'Sentry::Hub::Scope';
      is $captured->{exception}, $exception;
      is_UUID_string $captured->{hint}{event_id};
    };
  };

  it 'configure_scope()' => sub {
    my %user = (id => 1, email => 'john.doe@example.com');

    Sentry::SDK->configure_scope(sub ($scope) {
      $scope->set_tag(foo => 'bar');
      $scope->set_user({%user});
    });

    my $scope = $hub->get_current_scope();
    is_deeply $scope->tags => { foo => 'bar' };
    is_deeply $scope->user => \%user;
  };

  it 'add_breadcrumb()' => sub {
    my %breadcrumb = (
      type      => 'query',
      category  => 'mycat',
      data      => { my => 'data' },
      timestamp => time,
    );

    Sentry::SDK->add_breadcrumb({%breadcrumb});

    is_deeply $hub->get_current_scope()->breadcrumbs, [{%breadcrumb}];
  };

  it 'start_transaction()' => sub {
    Sentry::SDK->init({ traces_sample_rate => 1, });

    my $tx
      = Sentry::SDK->start_transaction(
        { name     => 'my transaction name', op => 'my.op', },
        { 'mydata' => { foo => 'bar' } });

    isa_ok $tx, 'Sentry::Tracing::Transaction';
    is $tx->name => 'my transaction name';
    is $tx->op   => 'my.op';
    ok defined $tx->start_timestamp;
    is_deeply $tx->tags => {
      "__sentry_sampleRate"     => 1,
      "__sentry_samplingMethod" => "client_rate"
    };
    ok $tx->sampled;
  };
};

runtests;
