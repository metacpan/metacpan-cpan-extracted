use Mojo::Base -strict, -signatures;

use Mojo::File;
# curfile missing in Mojolicious@^8. The dependency shall not be updated for
# the time being. For this reason `curfile` is duplicated for now.
# use lib curfile->sibling('lib')->to_string;
# See https://github.com/mojolicious/mojo/blob/4093223cae00eb516e38f2226749d2963597cca3/lib/Mojo/File.pm#L36
use lib Mojo::File->new(Cwd::realpath((caller)[1]))->sibling('lib')->to_string;

use Mojo::Util 'dumper';
use Sentry::Hub::Scope;
use Sentry::Severity;
use Sentry::Tracing::Span;
use Sentry::Tracing::Transaction;
use Test::Spec;

describe 'Sentry::Hub::Scope' => sub {
  my $scope;
  my $span;
  my $tx;

  before each => sub {
    $tx   = Sentry::Tracing::Transaction->new();
    $span = Sentry::Tracing::Span->new(
      { transaction => $tx, request => { url => 'http://example.com' } });
    $scope = Sentry::Hub::Scope->new({ span => $span });
  };

  describe 'apply_to_event()' => sub {

    it 'sets the request payload', sub {
      my $event = $scope->apply_to_event({});

      is_deeply $event->{request}, { url => 'http://example.com' };
    };

    describe 'level' => sub {
      it 'defaults to level "info"' => sub {
        my $event = $scope->apply_to_event({});

        is $event->{level}, Sentry::Severity->Info;
      };

      it 'does not override the event level' => sub {
        my $event
          = $scope->apply_to_event({ level => Sentry::Severity->Fatal });

        is $event->{level}, Sentry::Severity->Fatal;
      };
    };

  };
};

runtests;
