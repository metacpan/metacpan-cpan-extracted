#!perl

use Test2::V0 -no_srand;
use Test2::Require::Module 'CHI';

use Test::File::ShareDir -share => {
    -dist => {
        "Robots-Validate" => "share"
    }
};

use List::Util ();
use Module::Load qw( autoload );
use Net::DNS::Resolver::Mock;

use Robots::Validate;

autoload "CHI";

my $res = Net::DNS::Resolver::Mock->new;
$res->zonefile_parse(
    <<ZONE
crawl-66-249-66-67.googlebot.com  84569 A       66.249.66.67
67.66.249.66.in-addr.arpa. 84569 IN     PTR     crawl-66-249-66-67.googlebot.com.
ZONE
);

my %store;
my $cache = CHI->new(
    driver         => 'Memory',
    datastore      => \%store,
    key_digester   => 'SHA-256',
    max_key_length => 0,
);

ok my $rv = Robots::Validate->new(
    resolver => $res,
    cache    => $cache,
    cache_options => '8 hours',
  ),
  'Robots::Validate';

is $rv->cache_options, { expires_in => '8 hours' }, 'cache_options coercion';

my $has_google = List::Util::any { $_->{name} eq "google" } $rv->config->@*;
ok $has_google, "google in config";

ok $rv->_check_dns( 1, qr/\.googlebot\.com$/, '66.249.66.67' ), '_check_dns';

ok $rv->_agents, 'agents initialized';

is
  $rv->_revalidate(
    '66.249.66.67',
"Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.7871.186 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
  ),
  [ "google" => "googlebot" ],
  '_revalidate';

ok !%store || !$store{Default}->%*, 'empty cache';

is
  $rv->validate(
    '1.2.3.4',
"Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.7871.186 Mobile Safari/537.36"
  ),
  undef,
  'unknown UA';

ok !%store || !$store{Default}->%*, 'empty cache';

is $rv->validate(
    '1.2.3.4',
"Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.7871.186 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)",
  ),
  "",
  'identify a fake bot';

ok !%store || !$store{Default}->%*, 'empty cache (failure not cached)';

is $rv->validate(
    '1.2.3.4',
"Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.7871.186 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)",
    { cache_failure => 1 },
  ),
  "",
  'identify a fake bot';


ok !!%store && scalar(keys $store{Default}->%*) == 1, 'non-empty cache';

is
  $rv->validate(
    '1.2.3.4',
"Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.7871.186 Mobile Safari/537.36"
  ),
  undef,
  'unknown UA (same address as fake but not cached result)';

ok !!%store && scalar(keys $store{Default}->%*) == 1, 'non-empty cache';

is
  $rv->validate(
    '66.249.66.67',
"Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.7871.186 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
  ),
  [ "google" => "googlebot" ],
  'validate';

ok !!%store && scalar(keys $store{Default}->%*) == 2, 'non-empty cache';

is
  $rv->validate(
    '66.249.66.67',
"Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.7871.186 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
  ),
  [ "google" => "googlebot" ],
  'validate';

ok !!%store && scalar(keys $store{Default}->%*) == 2, 'non-empty cache';

done_testing;
