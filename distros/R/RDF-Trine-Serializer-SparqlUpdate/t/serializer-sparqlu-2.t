# use Test::More tests => 5;
use Test::More skip_all => 'TODO: write actual tests';
use Test::Differences;
BEGIN { use_ok('RDF::Trine::Serializer::SparqlUpdate') };

use strict;
use warnings;
use Data::Dumper;

use RDF::Trine;
use RDF::Trine::Parser;

my $default = RDF::Trine::Node::Nil->new;
my $store	= RDF::Trine::Store->temporary_store();
my $model	= RDF::Trine::Model->new( $store );
my $model_quad	= RDF::Trine::Model->temporary_model;
my $model_quad_other	= RDF::Trine::Model->temporary_model;

my $cx1 = RDF::Trine::Node::Resource->new('http://w3c.org/');
my $cx2 = RDF::Trine::Node::Resource->new('http://perlrdf.org/');

my $rdf		= RDF::Trine::Namespace->new('http://www.w3.org/1999/02/22-rdf-syntax-ns#');
my $foaf	= RDF::Trine::Namespace->new('http://xmlns.com/foaf/0.1/');
my $kasei	= RDF::Trine::Namespace->new('http://kasei.us/');

my $page	= $kasei->home; 
my $g		= RDF::Trine::Node::Blank->new('greg');
my $st0		= RDF::Trine::Statement->new( $g, $rdf->type, $foaf->Person );
my $st1		= RDF::Trine::Statement->new( $g, $foaf->name, RDF::Trine::Node::Literal->new('Greg') );
my $st2		= RDF::Trine::Statement->new( $g, $foaf->homepage, $page );
my $st3		= RDF::Trine::Statement->new( $page, $rdf->type, $foaf->Document );
my $quad1   = RDF::Trine::Statement::Quad->new( $kasei->Perl, $rdf->type, $kasei->GoodStuff, $g );
$model->add_statement( $_ ) for ($st0, $st1, $st2, $st3);
$model_quad->add_statement( $_, $cx1 ) for ( $st0, $st2 );
$model_quad->add_statement( $_, $cx2 ) for ( $st3 );
$model_quad->add_statement( $_ ) for ( $st1 );
$model_quad->add_statement( $quad1 );
$model_quad_other->add_statement( $_, $cx1 ) for ( $st1, $st3 );
$model_quad_other->add_statement( $_, $cx2 ) for ( $st0 );
$model_quad_other->add_statement( $_ ) for ( $st2 );

my $ser3 = RDF::Trine::Serializer::SparqlUpdate->new;
my $ser4 = RDF::Trine::Serializer::SparqlUpdate->new( quad_semantics => 1);
my $ser3_atomic = RDF::Trine::Serializer::SparqlUpdate->new( atomic => 1 );
my $ser4_atomic = RDF::Trine::Serializer::SparqlUpdate->new( quad_semantics => 1, atomic => 1);


sub eq_or_diff_without_nl {
    for my $i(0,1) {
        $_[$i] =~ s/\n//g;
    }
    return eq_or_diff( @_ );
}
unified_diff;
{
    # my $test_iter = $model_quad_other->get_statements( undef, undef, undef, $default );
    # warn Dumper $ser4_atomic->serialize_to_string( $model_quad_other );
    # warn Dumper $ser3_atomic->serialize_to_string( $model_quad_other );
    # warn Dumper $ser3_atomic->serialize_to_string( $model_quad_other );
    # warn Dumper $ser3_atomic->serialize_to_string( $model_quad_other );
    # warn Dumper $ser4->serialize_to_string( $model_quad, delete => $model_quad_other );
    # warn Dumper   $ser4->serialize_to_string( $model_quad );
    # warn Dumper "\n----";
    # my $clos =  $ser4->serialize_to_io( $model_quad, delete => $model_quad_other )
    # # ->[3]
    # # ->get_all
    # ;
    # local $/;
    # warn Dumper <$clos>;
    # warn Dumper $clos->();
    # warn Dumper $clos->();
    # warn Dumper $clos->();
    # warn Dumper $clos->();
}
# {
#     my ($rh, $wh);
#     pipe($rh, $wh);
#     my $serializer	= RDF::Trine::Serializer::SparqlUpdate->new();
#     $serializer->serialize_model_to_file($wh, $model);
#     close($wh);
#     my $expect = q{INSERT DATA { 
# _:greg <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://xmlns.com/foaf/0.1/Person> .
# _:greg <http://xmlns.com/foaf/0.1/homepage> <http://kasei.us/> .
# _:greg <http://xmlns.com/foaf/0.1/name> "Greg" .
# <http://kasei.us/> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://xmlns.com/foaf/0.1/Document> .
# };
# };
#     my $got = do { local $/; <$rh> };
#     eq_or_diff_without_nl ($expect, $got, 'serialize_model_to_file');
#     # warn Dumper \@got;
#     # is_deeply( [@expect], [@got], 'serialize_model_to_file');
# }

# {
#     my $iter	= $model->get_statements( undef, $rdf->type, undef );
	
#     my ($rh, $wh);
#     pipe($rh, $wh);
#     my $serializer	= RDF::Trine::Serializer::SparqlUpdate->new();
#     $serializer->serialize_iterator_to_file($wh, $iter);
#     close($wh);

#     my @expect = split "\n", <<'EOEXP';
# INSERT DATA { 
# _:greg <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://xmlns.com/foaf/0.1/Person> .
# <http://kasei.us/> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://xmlns.com/foaf/0.1/Document> .
# };
# EOEXP
#     my @got = grep {$_} map {chomp; $_} (<$rh>);
	
#     # warn Dumper \@got;
	
#     is_deeply( [@expect], [@got], 'serialize_iterator_to_file');
# }

# {
#     my $serializer	= RDF::Trine::Serializer::SparqlUpdate->new();
#     my $iter		= $model->get_statements( undef, $rdf->type, undef );
#     my $string		= $serializer->serialize_iterator_to_string( $iter );
#     my @expect = split "\n", <<'EOEXP';
# INSERT DATA { 
# _:greg <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://xmlns.com/foaf/0.1/Person> .
# <http://kasei.us/> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://xmlns.com/foaf/0.1/Document> .
# };
# EOEXP
#     my @got = grep { $_ } (split "\n", $string);
	
#     # warn Dumper \@got;
	
#     is_deeply( [@expect], [@got], 'serialize_iterator_to_string');
# }

# SKIP: {
#     skip 'ah have to fix this', 1 if 1;
#     # my $iter		= $model->get_statements( undef, $rdf->type, undef );
#     # my $string		= $serializer->serialize_iterator_to_string( $iter );
#     my $st4		= RDF::Trine::Statement->new( $page, $rdf->type, $foaf->NotDocument );
#     my $insert_model	= RDF::Trine::Model->temporary_model;
#     my $delete_model	= RDF::Trine::Model->temporary_model;
#     $delete_model->add_statement( $st3 );
#     $insert_model->add_statement( $st4 );

#     my $serializer	= RDF::Trine::Serializer::SparqlUpdate->new(delete_model => $delete_model);
#     is( $serializer->{delete_model}, $delete_model, '$self->{delete_model} is set');
#     my $string = $serializer->serialize_model_to_string( $insert_model );
#     TODO: {
#         local $TODO = 'Make options atomic per serialization';
#         is( $serializer->{delete_model}, undef, '$self->{delete_model} is not set anymore');
#     }
#     my @expect = split "\n", <<'EOEXP';
# DELETE DATA {<http://kasei.us/> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://xmlns.com/foaf/0.1/Document> .
# }
# INSERT {<http://kasei.us/> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://xmlns.com/foaf/0.1/NotDocument> .
# }
# WHERE {}
# EOEXP
#     my @got = grep { $_} (split "\n", $string);
	
#     # warn Dumper \@got;
	
#     is_deeply( [@expect], [@got], 'serialize_iterator_to_string with delete clause');
# }

