# This file is part of Pootle-Client.

package t::Mock::Resource::Units;

use Modern::Perl '2015';
use utf8;
binmode STDOUT, ':encoding(UTF-8)';
binmode STDERR, ':encoding(UTF-8)';
use feature 'signatures'; no warnings "experimental::signatures";
use Carp::Always;
use Try::Tiny;
use Scalar::Util qw(blessed);


use base('t::Mock::Resource');

use Pootle::Resource::Unit;

my $objects;
my $lookup;
my $responseDump;

sub one($papi, $endpoint) {
  ($objects, $lookup) = __PACKAGE__->init($responseDump, 'Pootle::Resource::Unit') unless ($objects && $lookup);
  return $lookup->{$endpoint};
}

sub all($papi) {
  ($objects, $lookup) = __PACKAGE__->init($responseDump, 'Pootle::Resource::Unit') unless ($objects && $lookup);
  return $objects if $objects;
}

$responseDump = [
  {
    'commented_on' => '2017-05-11T19:17:51',
    'context' => '',
    'developer_comment' => '',
    'locations' => 'intranet-tmpl/prog/en/xslt/MARC21slim2MODS32.xsl:946',
    'mtime' => '2017-06-16T00:45:09',
    'resource_uri' => '/api/v1/units/20043867/',
    'source_f' => 'tape cassette',
    'source_length' => 13,
    'source_wordcount' => 2,
    'state' => 200,
    'store' => '/api/v1/stores/7578/',
    'submitted_on' => '2017-05-11T19:17:51',
    'suggestions' => [],
    'target_f' => 'nauhakasetti',
    'target_length' => 12,
    'target_wordcount' => 1,
    'translator_comment' => ''
  },
];

1;
