use strict;
use warnings;

use Test::More 'no_plan';

use SolarBeam;
use SolarBeam::Util 'escape';

sub is_query {
  my $url = shift;
  if (scalar(@_) % 2 == 1) {
    is($url->path, shift);
  }
  my %query = @_;
  is_deeply($url->query->to_hash, \%query);
}

my $sb = SolarBeam->new;
isa_ok($sb->url, 'Mojo::URL');
is $sb->url, 'http://localhost:8983/solr', 'default url';

$sb->url('http://localhost/foo');
isa_ok($sb->url, 'Mojo::URL');
is $sb->url, 'http://localhost/foo', 'custom url';

is(escape('hel*o "world'),  'hel*o "world');
is(escape(\'hel*o "world'), 'hel\\*o \\"world');

is($sb->_build_query('hello'), 'hello');
is($sb->_build_query(['%hello = %world', hello => '*', world => \'*']), '* = \\*');
is($sb->_build_query({hello => 'world'}), '(hello:(world))');
is($sb->_build_query({hello => ['hello', 'world']}), '(hello:(hello) OR hello:(world))');

is_query($sb->_build_url, '/select', wt => 'json');

is_query(
  $sb->_build_url({page => 5, rows => 10}), '/select',
  rows  => 10,
  start => 40,
  wt    => 'json'
);

is_query($sb->_build_url({fq => 'hello*'}), '/select', fq => 'hello*', wt => 'json');

is_query(
  $sb->_build_url({fq => ['(foo)', {bar => 1}, ['qux:%qux', qux => \'cool*']]}),

  '/select',
  wt => 'json',
  fq => ['(foo)', '(bar:(1))', 'qux:cool\*']
);

is_query(
  $sb->_build_url({fq => [['a:%@ OR a:%@', 1, 2]]}),

  '/select',
  'wt' => 'json',
  'fq' => 'a:1 OR a:2'
);

is_query(
  $sb->_build_url({facet => {field => 'identifier.owner', mincount => 1}}),

  '/select',
  wt               => 'json',
  facet            => 'true',
  'facet.field'    => 'identifier.owner',
  'facet.mincount' => 1
);


is_query(
  $sb->_build_url(
    {facet => {range => {-value => 'year', gap => 100, start => 0, end => 2000}, mincount => 1}}
  ),

  '/select',
  wt                  => 'json',
  facet               => 'true',
  'facet.range'       => 'year',
  'facet.range.gap'   => 100,
  'facet.range.start' => 0,
  'facet.range.end'   => 2000,
  'facet.mincount'    => 1
);

is_query(
  $sb->_build_url({-endpoint => 'terms', terms => {fl => 'artifact.name'}}), '/terms',
  wt         => 'json',
  terms      => 'true',
  'terms.fl' => 'artifact.name'
);

my $sbc = SolarBeam->new(url => 'http://localhost/', default_query => {awesome => 1});
is_query($sbc->_build_url({cool => 1}), '/select', wt => 'json', cool => 1, awesome => 1);


