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
    driver         => 'RawMemory',
    datastore      => \%store,
);

ok my $rv = Robots::Validate->new(
    resolver => $res,
    cache    => $cache,
    cache_options => { expires_in => 300, cache_failure => 60 },
  ),
  'Robots::Validate';

my $has_google = List::Util::any { $_->{name} eq "google" } $rv->config->@*;
ok $has_google, "google in config";

ok $rv->_check_dns( 1, qr/\.googlebot\.com$/, '66.249.66.67' ), '_check_dns';

ok $rv->_agents, 'agents initialized';

is
  $rv->validate(
    '1.2.3.4',
"Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.7871.186 Mobile Safari/537.36"
  ),
  undef,
  'unknown UA';

ok !%store || !$store{Default}->%*, 'empty cache';

my $ua = "Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.7871.186 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)";

my $time = time;
ok $rv->bad_robot( '1.2.3.4', $ua ), 'identify a fake bot';

ok !!%store && scalar(keys $store{Default}->%*) == 1, 'failure is cached';

ok my $obj = $store{Default}{ join $;, '1.2.3.4', $ua }, 'CHI::CachedObject';

ok $obj->expires_at >= ( $time + 59 ), 'expected expiration for failure';
ok $obj->expires_at < ( $time + 299 ), 'expiration is less than normal expiration';

is
  $rv->validate(
    '66.249.66.67',
"Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.7871.186 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
  ),
  [ "google" => "googlebot" ],
  'validate';

ok !!%store && scalar(keys $store{Default}->%*) == 2, 'non-empty cache';

$time = time;

is
  $rv->validate( '66.249.66.67', $ua ),
  [ "google" => "googlebot" ],
  'validate';

ok !!%store && scalar(keys $store{Default}->%*) == 2, 'non-empty cache';

ok $obj = $store{Default}{ join $;, '66.249.66.67', $ua }, 'CHI::CachedObject';

note $time;
note $obj->expires_at;

ok $obj->expires_at >= ( $time + 299 ), 'expected expiration for success';

done_testing;
