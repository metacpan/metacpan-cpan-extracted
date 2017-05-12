use lib 't/lib';
use Test::Monitis tests => 1;

my $api = new_ok 'Monitis',
  [ api_key    => $ENV{MONITIS_API_KEY},
    secret_key => $ENV{MONITIS_SECRET_KEY}
  ];
