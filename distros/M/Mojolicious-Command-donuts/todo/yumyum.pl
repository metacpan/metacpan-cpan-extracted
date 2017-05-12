use Mojo::Base -strict;

use Mojo::UserAgent;

my $ua = Mojo::UserAgent->new();

say $ua->transactor->name;

use Mojo::Util qw(dumper);

#say $ua->get(
#    'http://yumyumdonuts.com/locations/' => {    #
#        Accept => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
#    }
#)->res->body;


my $url = Mojo::URL->new('http://www.mapquestapi.com/search/v2/radius');

$url->query(
    _           => 1434233078582,
    ambiguities => 'ignore',
    hostedData  => 'mqap.33454_DunkinDonuts',
    key         => 'Gmjtd|lu6t2luan5%2C72%3Do5-larsq',
    maxMatches  => 50,
    origin      => 91506,
    radius      => 30,
    units       => 'm',
);
say $ua->get($url)->res->json('/searchResults')->;
