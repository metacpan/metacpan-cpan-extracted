use strict;
use warnings;
use Test::More;

use Mojo::JSON;
use File::Basename;
use Mojo::Message::Response;
use Mojo::Transaction::HTTP;

use_ok 'SolarBeam::Response';

my $res = SolarBeam::Response->new->parse(fixture('simple'));
ok(!$res->error);
is($res->num_found,            2462);
is($res->pager->total_entries, 2462);
ok($res->docs);
is(scalar @{$res->docs}, 10);

$res = SolarBeam::Response->new->parse(fixture('facets'));
ok(!$res->error);

ok($res->facet_fields);
is(scalar @{$res->facet_fields->{'identifier.owner'}},     84);
is($res->facet_fields->{'identifier.owner'}->[0]->{value}, 'NF');
is($res->facet_fields->{'identifier.owner'}->[0]->{count}, 358262);


$res = SolarBeam::Response->new->parse(fixture('ranges'));
ok(!$res->error);
ok($res->facet_ranges);
my $year = $res->facet_ranges->{'artifact.ingress.production.fromYear'};
is($year->{start},                -4000);
is($year->{end},                  3000);
is(scalar @{$year->{counts}},     26);
is($year->{counts}->[0]->{value}, 1750);
is($year->{counts}->[0]->{count}, 20);

$res = SolarBeam::Response->new->parse(fixture('terms'));
ok(!$res->error);
ok($res->terms);
is(scalar @{$res->terms->{'artifact.name'}},     10);
is($res->terms->{'artifact.name'}->[0]->{value}, 'oslo');
is($res->terms->{'artifact.name'}->[0]->{count}, 2535);

$res = SolarBeam::Response->new->parse(fixture('fail'));
ok($res->error);

$res = SolarBeam::Response->new->parse(fixture('unknown'));
ok(!$res->error);

my $tx = Mojo::Transaction::HTTP->new;
$tx->req->error({});
is_deeply parse()->error, {message => 'Unknown error'}, 'empty response';

$tx->req->error({message => 'oops!'});
is_deeply parse()->error, {message => 'oops!'}, 'request error';

$tx->req->error(undef);
$tx->res->error({code => 500, message => 'Internal server error'});
is_deeply parse()->error, {code => 500, message => 'Internal server error'}, 'response error';

$tx->res->error(undef);
$tx->res->code(401);
is_deeply parse()->error, {code => 401, message => 'Missing response headers.'},
  'missing response headers';

$tx->res->code(403);
$tx->res->body('{"error":{"code":42,"msg":"yikes"}}');
is_deeply parse()->error, {code => 42, message => 'yikes'}, 'solr json error';

delete $tx->res->{json};
$tx->res->body('<title>xml?</title>');
is_deeply parse()->error, {code => 403, message => '<title>xml?</title>'}, 'fallback error';

done_testing;

sub fixture {
  my $name = shift;
  my $file = dirname(__FILE__) . '/fixtures/' . $name . '.json';
  open(FILE, $file) or die 'Could not open ' . $file;
  my $content = <FILE>;
  close(FILE);
  my $tx = Mojo::Transaction::HTTP->new;
  $tx->res(Mojo::Message::Response->new(code => 200)->body($content));
  return $tx;
}

sub parse {
  return SolarBeam::Response->new->parse($tx);
}
