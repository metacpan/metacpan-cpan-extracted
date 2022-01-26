use Test::More;
use lib '../lib'; #test
use Test::Warn;
use File::Spec;
use Mock::Quick;

my $dir = -d 't' ? 't' : '.';

my $neo4j35_endpt = "http://localhost:32805";
my $neo4j40_endpt = "http://localhost:32808";
$ENV{REST_NEO4P_AGENT_MODULE} = 'LWP::UserAgent';
require REST::Neo4p;

my $ht_control = qtakeover 'HTTP::Tiny';
my $ag_control = qtakeover 'REST::Neo4p::Agent';
$ht_control->override(
  get => sub {
    shift;
    local $/;
    my ($f, $json);
    for ($_[0]) {
      /32805\/?$/ && do {
	open $f, File::Spec->catfile($dir,qw'samples 3.5-response.txt') or die $!;
	last;
      };
      /32805\/db\/data\/?$/ && do {
	open $f, File::Spec->catfile($dir,qw'samples 3.5-db-data-response.txt') or die $!;
	last;
      };
      /32808/ && do {
	open $f, File::Spec->catfile($dir,qw'samples 4.0-response.txt') or die $!;
	last;
      };
    }
    $json = <$f>;
    close($f);
    return {success => 1, content => $json};
  });

$ag_control->override( connect => sub { 1 } );

is $REST::Neo4p::AGENT_MODULE, 'LWP::UserAgent';
*REST::Neo4p::get_neo4j_version = sub { 3 };
ok(REST::Neo4p->connect($neo4j35_endpt));
is $REST::Neo4p::AGENT_MODULE, 'LWP::UserAgent';
*REST::Neo4p::get_neo4j_version = sub { 4 };
warning_like { REST::Neo4p->connect($neo4j40_endpt) } qr/Neo4j::Driver/;
is $REST::Neo4p::AGENT_MODULE, 'Neo4j::Driver';

done_testing;
1;
