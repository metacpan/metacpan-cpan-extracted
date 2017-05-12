use Test::More;
use Test::Moose;
# use Devel::PartialDump qw(warn);
use MooseX::Semantic::Test::Person;
use Data::Dumper;

# warn Dumper [ MooseX::Semantic::Test::Person->meta->get_all_class_attributes ];
is(MooseX::Semantic::Test::Person->get_rdf_type(0)->uri, 'http://xmlns.com/foaf/0.1/Person', 
    'rdf_type of MooseX::Semantic::Test::Person is "foaf:Person"');
# warn Dumper(
    # MooseX::Semantic::Test::Person->rdf_type
# );
# {
#     package My::Test::Model;
#     use Moose;
#     with (
#         'MooseX::Semantic::Role::WithRdfType' => {
#             types => ['abc'],
#         },
#     );
#     1;
# }

done_testing;
