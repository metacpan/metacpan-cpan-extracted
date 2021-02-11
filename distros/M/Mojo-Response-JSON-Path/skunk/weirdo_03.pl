use Weirdo;
use Mojo::Util qw/dumper/;
use Mojo::UserAgent;

$\ = "\n"; $, = "\t";

my $ua = Mojo::UserAgent->new;

my $url = Mojo::URL->new("https://www.wikidata.org/w/api.php?action=wbgetentities&format=json&props=sitelinks&ids=Q19675&sitefilter=enwiki");

my $id = "Q100148272";
$url->query({ ids => $id });

$tx = $ua->get($url);

my $json = $tx->res->json();

print dumper $json;

print dumper $tx->res->json('//title');

my $u = Weirdo->new($json);

print dumper $u->get('$.entities.Q100148272.sitelinks.enwiki.title');

print dumper $u->get('..title');


