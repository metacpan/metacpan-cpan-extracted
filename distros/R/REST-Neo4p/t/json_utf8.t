#-*-perl-*-
use Test::More tests => 38;
use Module::Build;
use lib '../lib';
use lib 't/lib';
use Neo4p::Connect;
use strict;
use warnings;
my @cleanup;
use_ok('REST::Neo4p');

use 5.012;
use utf8;
use Data::Dumper;

my $build;
my ($user,$pass);

eval {
  $build = Module::Build->current;
  $user = $build->notes('user');
  $pass = $build->notes('pass');
};

my $TEST_SERVER = $build ? $build->notes('test_server') : 'http://127.0.0.1:7474';

my $not_connected = connect($TEST_SERVER,$user,$pass);
diag "Test server unavailable (".$not_connected->message.") : tests skipped" if $not_connected;


sub to_hex ($) {
  join ' ', map { sprintf "%02x", ord $_ } split m//, shift;
}

SKIP : {
  skip 'no local connection to neo4j', 37 if $not_connected;

  my %props = (
    singlebyte => "\N{U+0025}",  # '%' PERCENT SIGN = 0x25
    supplement => "\N{U+00E4}",  # 'ä' LATIN SMALL LETTER A WITH DIAERESIS = 0xc3a4
    extension  => "\N{U+0100}",  # 'Ā' LATIN CAPITAL LETTER A WITH MACRON = 0xc480
    threebytes => "\N{U+D55C}",  # '한' HANGUL SYLLABLE HAN = 0xed959c
    smp        => "\N{U+1F600}",  # '😀' GRINNING FACE = 0xf09f9880
    decomposed => "o\N{U+0302}",  # 'ô' LATIN SMALL LETTER O + COMBINING CIRCUMFLEX ACCENT = 0x6fcc82
    mixed      => "%äĀ한😀ô",  # 0x25c3a4c480ed959cf09f98806fcc82
  );
  my @keys = sort keys %props;
  my ($row, $simple);

  my $n1 = REST::Neo4p::Node->new( \%props );
  ok $n1, 'create node' and push @cleanup, $n1;
  my $id_param = { id => 0 + $n1->id };

  foreach my $key (@keys) {
    is to_hex $n1->get_property($key), to_hex $props{$key}, "via node->get_property: $key";
  }
  # worked as expected (fetches directly from server via $agent->get_data)
  # ->get_properties worked as well
  # ->as_simple worked as well (probably via the entity cache)

  my $q2 = REST::Neo4p::Query->new("MATCH (n) WHERE id(n) = {id} RETURN n", $id_param);
  $q2->{ResponseAsObjects} = 0;
  $q2->execute;
  eval { $row = $q2->fetch };
  ok $row, 'fetch node simple';
  $simple = $row->[0];
  foreach my $key (@keys) {
    is to_hex $simple->{$key}, to_hex $props{$key}, "via simple: $key";
  }
  # Node::simple_from_json_response
  $q2->finish;

  my $q3 = REST::Neo4p::Query->new("MATCH (n) WHERE id(n) = {id} RETURN n." . (join ", n.", @keys), $id_param);
  $q3->execute;
  eval { $row = $q3->fetch };
  ok $row, 'fetch node properties';
  for (my $i = 0; $i < @keys; $i++) {
    is to_hex $row->[$i], to_hex $props{$keys[$i]}, "via properties: $keys[$i]";
  }
  # Query::_process_row
  $q3->finish;

  my $n2 = REST::Neo4p::Node->new();
  ok $n2, 'create node' and push @cleanup, $n2;
  my $r1 = REST::Neo4p::Relationship->new( $n1 => $n2, 'TEST', \%props );
  ok $r1, 'create rel' and push @cleanup, $r1;
  $id_param = { id => 0 + $r1->id };
  
  my $q5 = REST::Neo4p::Query->new("MATCH ()-[r]-() WHERE id(r) = {id} RETURN r." . (join ", r.", @keys), $id_param);
  $q5->execute;
  eval { $row = $q5->fetch };
  ok $row, 'fetch rel properties';
  for (my $i = 0; $i < @keys; $i++) {
    is to_hex $row->[$i], to_hex $props{$keys[$i]}, "via properties: $keys[$i]";
  }
  # Relationship::simple_from_json_response
  $q5->finish;

  1;
}

TODO : {
  # same issue (no ->utf8 on json parser constructor) existed also in:
  # Neo4p::Batch
  # Neo4p::get_nodes_by_label
  # Neo4p::Constraint
  # (not tested here)
  1;
}

CLEANUP : {
  ok $_->remove, 'entity removed' for reverse grep {ref $_ && $_->can('remove')} @cleanup;
}

done_testing;
