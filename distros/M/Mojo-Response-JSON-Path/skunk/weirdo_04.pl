use Mojo::Util qw/dumper/;
use Mojo::Response::JSON::Path;
use Mojo::UserAgent;
use Time::HiRes qw/time/;

$\ = "\n"; $, = "\t";

my $ua = Mojo::UserAgent->new;

my $url = Mojo::URL->new("http://localhost:3000");

my $id = "Q100148272";
$url->query({ ids => $id });

my $start = time();
for (0..1) {
    $tx = $ua->get($url);
    my $json = $tx->res->json('$.entities');
    print dumper $json;
}

print time() - $start;

# print dumper $json;

# print dumper $tx->res->json('//title');

# my $u = Weirdo->new($json);

# print dumper $u->get('$.entities.Q100148272.sitelinks.enwiki.title');

# print dumper $u->get('..title');


