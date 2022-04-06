use Mojo::Base -strict;

use Mojo::File;
# curfile missing in Mojolicious@^8. The dependency shall not be updated for
# the time being. For this reason `curfile` is duplicated for now.
# use lib curfile->sibling('lib')->to_string;
# See https://github.com/mojolicious/mojo/blob/4093223cae00eb516e38f2226749d2963597cca3/lib/Mojo/File.pm#L36
use lib Mojo::File->new(Cwd::realpath((caller)[1]))->sibling('lib')->to_string;

use CGI;
use Capture::Tiny qw(capture);
use Mock::Mojo::UserAgent;
use Mojo::Util 'dumper';
use Sentry::Hub;
use Test::Spec;

$CGI::USE_PARAM_SEMICOLONS = 0;

{

  package My::Application;
  use Mojo::Base 'CGI::Application', -signatures;

  use CGI::Application::Plugin::Sentry;

  sub cgiapp_init ($self) {
    $self->param(
      sentry_options => {
        dsn =>
          'http://ff21cbe6ddaf4314833eabd2075e38e3@example.com/foo/bar/2',
        traces_sample_rate => 1
      }
    );
  }

  sub cgiapp_prerun ($self, $rm) {
    Sentry::SDK->configure_scope(sub ($scope) {
      $scope->set_tags({ bla => 'blubb' });
    });
  }

  sub setup ($self) {
    $self->start_mode('mode1');
    $self->run_modes('mode1' => \&mode1);
  }

  sub mode1 {
    Sentry::SDK->capture_message('hello');
    return 'abc';
  }
}

describe 'CGI::Application::Plugin::Sentry' => sub {
  my $app;
  my $http;

  before each => sub {
    $http = Mock::Mojo::UserAgent->new;

    $app = My::Application->new;

    my $client = Sentry::Hub->get_current_hub->client;
    $client->_transport->_http($http);
  };

  describe 'GET mode1' => sub {
    my $out;
    my $err;

    before each => sub {
      local $ENV{HTTP_HOST}      = 'example.com';
      local $ENV{HTTPS}          = 'ON';
      local $ENV{QUERY_STRING}   = 'a=b&d=e';
      local $ENV{REQUEST_METHOD} = 'GET';
      local $ENV{REQUEST_URI}    = '/abc/def';

      ($out, $err) = capture {
        $app->run;
      };

      die $err if $err;
    };

    it 'it returns the unaltered http response' => sub {
      is $out, "Content-Type: text/html; charset=ISO-8859-1\r\n\r\nabc";
    };

    it 'send an event to the sentry server' => sub {
      # First: info notification; second: Transaction request
      is scalar $http->requests->@*, 2;
    };

    it 'provided request details' => sub {
      my $event = $http->requests->[0]{body};

      is_deeply $event->{request}{headers}, { "HTTP_HOST" => "example.com" };
      is_deeply $event->{request}{query},   { a           => 'b', d => 'e' };
      is $event->{request}{url}, 'https://example.com/abc/def?a=b&d=e';
    };

    it 'set tags' => sub {
      my $event = $http->requests->[0]{body};

      is $event->{tags}{bla},         'blubb';
      is $event->{tags}{transaction}, 'GET mode1';
    };

    it 'send a message to sentry' => sub {
      my $event = $http->requests->[0]{body};

      is $event->{message}, 'hello';
    };
  };

};

runtests;
