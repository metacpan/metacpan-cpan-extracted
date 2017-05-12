use strict;
use warnings;
use Test::More tests => 15;
use Test::Deep;
use Try::Tiny;

use PomBase::Chobo::OntologyTerm;

my $alt_id_1 = "GO:0015457";
my $alt_id_2 = "GO:0015460";
my $term_arg = {
  id => "GO:0006810",
  name => "transport",
  namespace => "biological_process",
  alt_id => [$alt_id_1, $alt_id_2],
  synonym => [
    {
      synonym => "auxiliary transport protein activity",
      scope => "RELATED",
      dbxrefs => ["GOC:mah", "XDB:1234"],
    },
    {
      synonym => "small molecule transport",
      scope => "NARROW",
      dbxrefs => [],
    }
  ],
  source_file_line_number => __LINE__,
  source_file => $0,
};

my $term = PomBase::Chobo::OntologyTerm->make_object($term_arg);

is (ref $term, "PomBase::Chobo::OntologyTerm");

is ($term->id(), "GO:0006810");
is ($term->name(), "transport");

my $expected_term_as_string = "[Term]
id: GO:0006810
name: transport
alt_id: GO:0015457
alt_id: GO:0015460
namespace: biological_process
synonym: auxiliary transport protein activity RELATED [GOC:mah, XDB:1234]
synonym: small molecule transport NARROW []";

is ($term->to_string(), $expected_term_as_string);

my $merge_term_no_values =
  PomBase::Chobo::OntologyTerm->make_object({
    id => "GO:0006810",
    source_file_line_number => __LINE__,
    source_file => $0,
  });

$term->merge($merge_term_no_values);
is ($term->to_string(), $expected_term_as_string);

my $merge_term_same = $term;

$term->merge($merge_term_same);
is ($term->to_string(), $expected_term_as_string);

my $merge_term_clone = clone $term;

$term->merge($merge_term_clone);
is ($term->to_string(), $expected_term_as_string);

my $term_different_name = clone $term;
$term_different_name->{name} = "different transport";

use Capture::Tiny qw(capture);

my ($stdout, $stderr, $exit) = capture {
  $term->merge($term_different_name);
};

like ($stderr, qr/name" tag of this stanza .* differs from previously/,
      'term merge error');

my$term_no_name = clone $term;
delete $term_no_name->{name};

$term->merge($merge_term_clone);
is ($term->to_string(), $expected_term_as_string);

ok (!defined $term_no_name->name());

$term_no_name->merge($term);
is ($term_no_name->to_string(), $expected_term_as_string);

my @extra_alt_ids = ("GO:222222", "GO:111111");
my $term_extra_alt_id =
  PomBase::Chobo::OntologyTerm->make_object({
    id => "GO:0006810",
    alt_id => [@extra_alt_ids],
    source_file_line_number => __LINE__,
    source_file => $0,
  });

$term_extra_alt_id->merge($term);

cmp_deeply($term_extra_alt_id->alt_id(),
           [sort($alt_id_1, $alt_id_2, @extra_alt_ids)]);

my $merge_alt_id = "GO:99999";
my $merge_id = "GO:0012345";

sub make_test_merge_term
{
  return PomBase::Chobo::OntologyTerm->make_object({
    id => $merge_id,
    alt_id =>  [$term->id(), $merge_alt_id],
    is_a => ["GO:33333"],
    source_file_line_number => __LINE__,
    source_file => $0,
  });
}

my @expected_combined_alt_ids =
  sort($merge_alt_id, "GO:0006810", $alt_id_1, $alt_id_2);

my $alt_id_merge_term = make_test_merge_term();
$alt_id_merge_term->merge($term);

cmp_deeply($alt_id_merge_term->alt_id(),
           [@expected_combined_alt_ids]);

my $alt_id_merge_term_2 = make_test_merge_term();
my $alt_merged = clone $term;

$alt_merged->merge($alt_id_merge_term_2);

cmp_deeply([sort @{$alt_merged->alt_id()}],
           [sort($merge_alt_id, "GO:0012345", $alt_id_1, $alt_id_2)]);


my $term_name_clash_1 =
  PomBase::Chobo::OntologyTerm->make_object({
    id => "GO:0006810",
    alt_id => ["GO:0012345"],
    name => 'name_1',
    source_file_line_number => __LINE__,
    source_file => $0,
  });

my $term_name_clash_2 =
  PomBase::Chobo::OntologyTerm->make_object({
    id => "GO:0012345",
    alt_id => ["GO:0006810"],
    name => 'name_2',
    source_file_line_number => __LINE__,
    source_file => $0,
  });


($stdout, $stderr, $exit) = capture {
  $term_name_clash_1->merge($term_name_clash_2);
};

like ($stderr, qr/name" tag of this stanza .* differs from previously/);
