use Mojo::Base -strict, -signatures;

use Mojo::File;
# curfile missing in Mojolicious@^8. The dependency shall not be updated for
# the time being. For this reason `curfile` is duplicated for now.
# use lib curfile->sibling('lib')->to_string;
# See https://github.com/mojolicious/mojo/blob/4093223cae00eb516e38f2226749d2963597cca3/lib/Mojo/File.pm#L36
use lib Mojo::File->new(Cwd::realpath((caller)[1]))->sibling('lib')->to_string;

use Mock::Sentry::Transport::HTTP;
use Mojo::Util 'dumper';
use Scalar::Util 'looks_like_number';
use Sentry::Client;
use Sentry::Hub::Scope;
use Sentry::Severity;
use Test::Spec;

describe 'Sentry::Client' => sub {
  my $client;
  my $transport;

  before each => sub {
    $transport = Mock::Sentry::Transport::HTTP->new;
    $client    = Sentry::Client->new(_transport => $transport);
  };

  describe 'event_from_message()' => sub {
    it 'sets the event_id' => sub {
      my $event = $client->event_from_message('hello', Sentry::Severity->Info,
        { event_id => 'abc' });

      is_deeply $event =>
        { level => 'info', event_id => 'abc', message => 'hello' };
    };

    it 'skips the event_id' => sub {
      my $event = $client->event_from_message('hello');

      is_deeply $event =>
        { level => 'info', event_id => undef, message => 'hello' };
    };
  };

  describe 'capture_message()' => sub {
    it 'message only' => sub {
      $client->capture_message('hello');

      is $transport->events_sent->@*, 1;

      my %event = $transport->events_sent->[0]->%*;
      ok defined $event{event_id};
      ok looks_like_number($event{timestamp});
      is $event{message} => 'hello';
    };

    it 'w/ scope' => sub {
      my %tags  = (foo => 'bar', bar => 'baz');
      my $scope = Sentry::Hub::Scope->new(tags => {%tags});
      $client->capture_message('foo', undef, undef, $scope);

      is $transport->events_sent->@*, 1, 'Event was sent';

      my %event = $transport->events_sent->[0]->%*;
      is_deeply $event{tags}, \%tags;
    };
  };

  describe 'before_send' => sub {
    it 'before_send alters the event object' => sub {
      $client->_options->{before_send} = sub ($event) {
        $event->{dist} = 'abc';
        return $event;
      };

      $client->capture_message('katze');
      $transport->expect_to_have_sent_once;
      $transport->expect_to_have_sent(dist => 'abc');
    };

    it 'discarded the event' => sub {
      $client->_options->{before_send} = sub ($event) {
        return undef;
      };

      $client->capture_message('katze');
      $transport->expect_not_to_have_sent;
    };
  };
};

runtests;
