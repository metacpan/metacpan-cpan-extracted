use strict;
use warnings;
use Test::More;
use Plack::Builder;

sub build_handler {
  my @args = @_;
  builder {
    enable "Plack::Middleware::XForwardedFor", @args;
    sub { my $env = shift; is($env->{REMOTE_ADDR}, $env->{__expect}) };
  };
}

my @tests = (
  { REMOTE_ADDR          => "1.2.3.4",
    HTTP_X_FORWARDED_FOR => "9.8.7.6",
    __expect             => "9.8.7.6",
  },
  { REMOTE_ADDR          => "127.0.0.1",
    HTTP_X_FORWARDED_FOR => "10.55.1.2, 9.8.7.6",
    __expect             => "10.55.1.2",
  },
  { REMOTE_ADDR          => "1.2.3.4",
    HTTP_X_FORWARDED_FOR => "9.8.7.6",
    __trust              => "127.0.0.1",
    __expect             => "1.2.3.4",
  },
  { REMOTE_ADDR          => "127.0.0.1",
    HTTP_X_FORWARDED_FOR => "9.8.7.6",
    __trust              => "127.0.0.1",
    __expect             => "9.8.7.6",
  },
  { REMOTE_ADDR          => "127.0.0.1",
    HTTP_X_FORWARDED_FOR => "10.55.1.2, 9.8.7.6",
    __trust              => "127.0.0.1",
    __expect             => "9.8.7.6",
  },
  { REMOTE_ADDR          => "127.0.0.1",
    HTTP_X_FORWARDED_FOR => "2601:647:4200:1::100",
    __trust              => "127.0.0.1",
    __expect             => "2601:647:4200:1::100",
  },
  { REMOTE_ADDR          => "127.0.0.1",
    HTTP_X_FORWARDED_FOR => "9.8.7.6, 2601:647:4200:abcd::100",
    __trust              => ["127.0.0.1", "2601:647:4200:abcd::/64"],
    __expect             => "9.8.7.6",
  },
  { REMOTE_ADDR          => "2601:647:4200:abcd::100",
    HTTP_X_FORWARDED_FOR => "not-an-ip,9.8.7.6,127.0.0.1",
    __trust              => ["127.0.0.1", "2601:647:4200:abcd::/64"],
    __expect             => "9.8.7.6",
  },
  { REMOTE_ADDR          => "10.0.0.1",
    HTTP_X_FORWARDED_FOR => "::ffff:9.8.7.6",
    __trust              => ["10.0.0.0/24"],
    __expect             => "9.8.7.6",
  },
  { REMOTE_ADDR          => "127.0.0.1",
    HTTP_X_FORWARDED_FOR => "10.55.1.2, 9.8.7.6",
    __trust              => ["127.0.0.1", "9.8/16"],
    __expect             => "10.55.1.2",
  },
);

foreach my $env (@tests) {
  build_handler(trust => $env->{__trust})->($env);
}

done_testing();
