#!/usr/bin/env perl
use Mojolicious::Lite;

my $response = sub {
  my $c = shift;

  my $v = $c->validation;

  $v->optional('module')->in(qw/CoreAdminHome API/);
  $v->optional('method', 'trim');
  $v->optional('urls');
  $v->optional('format');
  $v->optional('action_url');
  $v->optional('action_name');
  $v->optional('idSite');
  $v->optional('token_auth', 'trim')
    ->in(qw/xyz anonymous/);
  $v->optional('a')->num;
  $v->optional('b')->num;

  my $method = $v->param('method') // 'Track';

  if ($v->has_error) {
    my $failed = join(',', @{$v->failed});
    warn $failed;
    return $c->render(
      text => $failed
    );
  };

  if ($method eq 'ExampleAPI.getPiwikVersion') {
    return $c->render(
      status => 200,
      json => {
        value => '3.6.1'
      }
    );
  }

  elsif ($method eq 'ExampleAPI.getAnswerToLife') {
    return $c->render(
      status => 200,
      json => {
        value => 42
      }
    );
  }

  elsif ($method eq 'ExampleAPI.getMoreInformationAnswerToLife') {
    return $c->render(
      status => 200,
      json => {
        value => 'Check http://en.wikipedia.org/wiki/The_Answer_to_Life,_the_Universe,_and_Everything'
      }
    );
  }

  elsif ($method eq 'ExampleAPI.getObject') {
    return $c->render(
      status => 200,
      json => {
        message => 'The API cannot handle this data structure.',
        result => 'error'
      }
    )
  }

  elsif ($method eq 'ExampleAPI.getCompetitionDatatable') {
    return $c->render(
      status => 200,
      json => [
        {
          'license' => 'GPL',
          'name' => 'piwik',
          'logo' => 'logo.png'
        },
        {
          'name' => 'google analytics',
          'license' => 'commercial'
        }
      ]
    )
  }

  elsif ($method eq 'ExampleAPI.getSum') {
    return $c->render(
      status => 200,
      json => {
        value => 12
          # ($v->param('a') + $v->param('b'))
      }
    );
  }

  elsif ($method eq 'ExampleAPI.getNull') {
    return $c->render(
      status => 200,
      json => {
        value => 0
      }
    )
  }

  elsif ($method eq 'ExampleAPI.getDescriptionArray') {
    return $c->render(
      status => 200,
      json => [
        'piwik',
        'free/libre',
        'web analytics',
        'free',
        "Strong message: \x{421}\x{432}\x{43e}\x{431}\x{43e}\x{434}\x{43d}\x{44b}\x{439} \x{422}\x{438}\x{431}\x{435}\x{442}"
      ]
    )
  }

  elsif ($method eq 'ExampleAPI.getMultiArray') {
    return $c->render(
      status => 200,
      json => {
        'Second Dimension' => [
          Mojo::JSON->true,
          Mojo::JSON->false,
          1,
          0,
          152,
          'test',
          {
            '42' => 'end'
          }
        ],
        'Limitation' => [
          'Multi dimensional arrays is only supported by format=JSON',
          'Known limitation'
        ]
      }
    )
  }

  elsif ($method eq 'Track') {
    return $c->render(
      status => 204,
      format => 'html',
      text => ''
    );
  };

  return $c->render(
    status => 404
  );
};


# Analysis API
get '/' => $response;
get '/matomo.php' => $response;
get '/piwik.php' => $response;


app->start;
