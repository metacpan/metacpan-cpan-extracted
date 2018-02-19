use strict;
use warnings;
use Test::More tests => 24;
use Test::Deep;

use lib qw(t/lib);

use PomBase::Chobo::OntologyData;
use PomBase::Chobo;
use ChoboTest::FakeHandle;

my $ontology_data = PomBase::Chobo::OntologyData->new();
my $fake_handle = ChoboTest::FakeHandle->new();

my $chobo = PomBase::Chobo->new(dbh => $fake_handle, ontology_data => $ontology_data);

is($ontology_data->get_terms(), 0);

$chobo->read_obo(filename => 't/data/mini_go.obo');

$chobo->chado_store();

is($ontology_data->get_terms(), 2);

my $cyanidin_name =
  qq|cyanidin 3-O-glucoside-(2"-O-xyloside) 6''-O-acyltransferase activity|;
my $cyanidin_def =
  qq|Catalysis of the reaction: cyanidin 3-O-beta-D-sambubioside +4-coumaryl-CoA <=> cyanidin 3-O-[2|;

cmp_deeply([
  sort {
    $a->{id} cmp $b->{id};
  } map {
    { name => $_->{name}, id => $_->{id}, definition => $_->{def}->{definition} }
  } $ontology_data->get_terms()],
           [{ name => 'molecular_function', id => 'GO:0003674',
              definition => 'Elemental activities, such as catalysis or binding, describing the actions of a gene product at the molecular level. A given gene product may exhibit one or more molecular functions.' },
            { name => $cyanidin_name, id => 'GO:0102583',
              definition => $cyanidin_def }]);


my $sth = $fake_handle->prepare("select cvterm_id, definition, name, cv_id from cvterm order by name");
$sth->execute();

my $cv_version_term = $sth->fetchrow_hashref();
is ($cv_version_term->{name}, 'cv_version');
my $cyanidin_term = $sth->fetchrow_hashref();
is ($cyanidin_term->{name}, $cyanidin_name);
is ($cyanidin_term->{definition}, $cyanidin_def);
my $exact_term = $sth->fetchrow_hashref();
is ($exact_term->{name}, 'exact');
my $is_a_term = $sth->fetchrow_hashref();
is ($is_a_term->{name}, 'is_a');
my $molecular_function_term = $sth->fetchrow_hashref();
is ($molecular_function_term->{name}, 'molecular_function');
my $narrow_term = $sth->fetchrow_hashref();
is ($narrow_term->{name}, 'narrow');
is ($sth->fetchrow_hashref(), undef);


$sth = $fake_handle->prepare("select subject_id, type_id, object_id from cvterm_relationship order by subject_id");
$sth->execute();

my $rel = $sth->fetchrow_hashref();

is ($rel->{subject_id}, $cyanidin_term->{cvterm_id});
is ($rel->{type_id}, $is_a_term->{cvterm_id});
is ($rel->{object_id}, $molecular_function_term->{cvterm_id});


$sth = $fake_handle->prepare("select cvterm_id, synonym, type_id from cvtermsynonym order by synonym");
$sth->execute();

my $synonym_1 = $sth->fetchrow_hashref();
my $synonym_2 = $sth->fetchrow_hashref();
my $synonym_3 = $sth->fetchrow_hashref();
my $synonym_4 = $sth->fetchrow_hashref();
my $synonym_5 = $sth->fetchrow_hashref();

cmp_deeply ($synonym_1,
            {
              type_id => $narrow_term->{cvterm_id},
              synonym => 'cyanidin 3-O-glucoside-"something"',
              cvterm_id => $cyanidin_term->{cvterm_id},
            });
cmp_deeply ($synonym_2,
            {
              type_id => $exact_term->{cvterm_id},
              synonym => 'cyanidin 3-O-glucoside-yadda',
              cvterm_id => $cyanidin_term->{cvterm_id},
            });
cmp_deeply ($synonym_3,
            {
              type_id => $exact_term->{cvterm_id},
              synonym => 'cyanidin 3-O-glucoside-yadda-one',
              cvterm_id => $cyanidin_term->{cvterm_id},
            });
cmp_deeply ($synonym_4,
            {
              type_id => $exact_term->{cvterm_id},
              synonym => 'cyanidin 3-O-glucoside-yadda-three',
              cvterm_id => $cyanidin_term->{cvterm_id},
            });
cmp_deeply ($synonym_5,
            {
              type_id => $exact_term->{cvterm_id},
              synonym => 'molecular function',
              cvterm_id => $molecular_function_term->{cvterm_id},
            });

is ($sth->fetchrow_hashref(), undef);


$sth = $fake_handle->prepare("select accession, dbxref_id from dbxref order by dbxref_id");
$sth->execute();

my $go_0005554_dbxref_id;

while (defined (my $dbxref = $sth->fetchrow_hashref())) {
  if ($dbxref->{accession} eq '0005554') {
    $go_0005554_dbxref_id = $dbxref->{dbxref_id};
  }
}

$sth = $fake_handle->prepare("select cvterm_id, dbxref_id from cvterm_dbxref order by cvterm_id");
$sth->execute();

my @cvterm_dbxrefs = ();

push @cvterm_dbxrefs, $sth->fetchrow_hashref();
push @cvterm_dbxrefs, $sth->fetchrow_hashref();
push @cvterm_dbxrefs, $sth->fetchrow_hashref();

is ($sth->fetchrow_hashref(), undef);

ok(scalar(grep {
  $_->{cvterm_id} == $molecular_function_term->{cvterm_id};
} @cvterm_dbxrefs) == 2);

my $chado_data = PomBase::Chobo::ChadoData->new(dbh => $fake_handle);

my @cv_version_values = $chado_data->get_cvprop_values('molecular_function', 'cv_version');

is(scalar(@cv_version_values), 1);
is($cv_version_values[0], 'releases/2016-05-07');


