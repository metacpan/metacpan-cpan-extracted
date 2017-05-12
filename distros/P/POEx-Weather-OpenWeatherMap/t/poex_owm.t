use Test::More;
use strict; use warnings FATAL => 'all';

my $mocked_response = 0;

{ no strict 'refs'; no warnings 'redefine';
  *{ 'POE::Component::Client::HTTP::_poco_weeble_request' } = sub { ... };
}

{ package
    MockHTTPClientSession;
  use strict; use warnings FATAL => 'all';
  use POE;
  use Weather::OpenWeatherMap::Test;

  POE::Session->create(
    inline_states => +{
      _start  => sub {
        $_[KERNEL]->alias_set( 'mockua' );
      },
      request => sub {
        my ($post_to, $http_req, $my_req) = @_[ARG0 .. $#_];

        my $http_response = mock_http_ua->request($http_req);
        $poe_kernel->call( $_[SENDER], $post_to,
          [ $http_req, $my_req ],
          [ $http_response ],
        );

        $mocked_response++;
        $_[KERNEL]->alias_remove( 'mockua' ) if $mocked_response == 2;
      },
    },
  );
}


use POE;
use POEx::Weather::OpenWeatherMap;

my $got = +{};
my $expected = +{
  'current weather ok'  => 2,
  'forecast weather ok' => 2,
  'hourly forecast ok'  => 2,
  'got error'           => 1,
};

alarm 60;
POE::Session->create(
  inline_states => +{
    _start => sub {
      $_[KERNEL]->sig(ALRM => 'time_out');

      $_[HEAP]->{wx} = POEx::Weather::OpenWeatherMap->new(
        api_key       => 'foo',
        event_prefix  => 'pwx_',
        ua_alias      => 'mockua',
        cache         => 1,
      );

      cmp_ok $_[HEAP]->{wx}->api_key, 'eq', 'foo',
        'api_key';
      $_[HEAP]->{wx}->set_api_key('bar');
      cmp_ok $_[HEAP]->{wx}->api_key, 'eq', 'bar',
        'set_api_key';

      ok $_[HEAP]->{wx}->cache, 'cache';
      ok !defined $_[HEAP]->{wx}->cache_dir,
        'cache_dir defaults to undef';
      ok !defined $_[HEAP]->{wx}->cache_expiry,
        'cache_expiry defaults to undef';

      $_[HEAP]->{wx}->start;
      $_[KERNEL]->yield('issue_tests');
    },

    issue_tests => sub {
      # pwx_weather
      $_[HEAP]->{wx}->get_weather(
        location => 'Manchester, NH',
        tag      => 'mytag',
      ) for 1 .. 2;

      # pwx_forecast
      $_[HEAP]->{wx}->get_weather(
        location => 'Manchester, NH',
        forecast => 1,
        days     => 3,
      ) for 1 .. 2;
      $_[HEAP]->{wx}->get_weather(
        location => 'Moscow, Russia',
        forecast => 1,
        hourly   => 1,
      ) for 1 .. 2;

      # pwx_error
      $_[HEAP]->{wx}->get_weather;

      $_[KERNEL]->delay( check_if_done => 1 );
    },

    pwx_weather => sub {
      my $res = $_[ARG0];
      $got->{'current weather ok'}++
        if $res->name eq 'Manchester';
    },

    pwx_forecast => sub {
      my $res = $_[ARG0];
      if ($res->hourly) {
        $got->{'hourly forecast ok'}++
          if $res->name eq 'Moscow'
            and $res->isa('Weather::OpenWeatherMap::Result::Forecast')
      } else {
        $got->{'forecast weather ok'}++
          if $res->name eq 'Manchester'
          and $res->isa('Weather::OpenWeatherMap::Result::Forecast')
      }
    },

    pwx_error => sub {
      my $err = $_[ARG0];
      $got->{'got error'}++
    },

    time_out => sub {
      $_[HEAP]->{wx}->stop;
      $_[KERNEL]->delay('check_if_done');
      fail "Timed out";
    },

    check_if_done => sub {
      my $done;
      if (keys %$expected == keys %$got) {
        $done = 1;
        for my $key (keys %$expected) {
          $done = 0 unless $expected->{$key} == $got->{$key}
        }
      }
      $_[HEAP]->{wx}->stop if $done;
      $_[KERNEL]->delay( check_if_done => 1 ) unless $done;
    },
  },
);

POE::Kernel->run;

is_deeply $got, $expected, 'got expected results ok';

done_testing
