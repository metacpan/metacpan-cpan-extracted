#=======================================================================
# rdf_resource.t
#=======================================================================
use common::sense;
use Test::Most tests => 3;
use Data::Dumper;
{
    package SemTest;
    use Moose;
    with qw(MooseX::Semantic::Role::Resource);
    has foo => (
        # is => 'rw' ,
        traits => ['Semantic'],
        uri => 'http://bar.baz/foo',
    );
}

my $t1 = SemTest->new();
my $t2 = SemTest->new(
    rdf_about => 'foo',
);
# warn Dumper $t->rdf_about;
ok( $t1->is_auto_generated, 't1 has auto-generated ID' );
ok( ! $t2->is_auto_generated, 't1 has explicit rdf_about' );
$t1->rdf_about('bar');
ok( ! $t1->is_auto_generated, 'Now t1 has explicit rdf_about' );




