use Test::More tests => 5;
use Data::Dumper;
use RDF::Trine qw(iri);
use MooseX::Semantic::Test::Person;
use MooseX::Semantic::Util::TypeConstraintWalker;

sub simple_type_walker {
    {
        package Foo;
        use Moose;
        with 'MooseX::Semantic::Util::TypeConstraintWalker';
        has val => (
            is => 'rw',
            isa => 'ArrayRef[HashRef[Str]]',
        );
        1;
    }
    my $f = Foo->new;
    # by attr
    ok( ! $f->_find_parent_type( $f->meta->get_attribute('val'), 'RefXYZ' ), 'Invalid Type') ;
    ok( $f->_find_parent_type( $f->meta->get_attribute('val'), 'Ref' ), 'Reference') ;
    # by type_constraint
    ok( $f->_find_parent_type( $f->meta->get_attribute('val')->type_constraint, 'Ref' ), 'Reference') ;
    # by object and attr_name
    ok( $f->_find_parent_type( 'val', 'Ref' ), 'Reference') ;
    # warn Dumper $f->_find_parent_type( $f->meta->get_attribute('val'), 'RefZ' );
}

sub class_name_finder {
    {
        package Bar;
        use Moose;
        use Moose::Util::TypeConstraints;
        
        subtype 'SpecialResource',
            as 'MooseX::Semantic::Test::Person';
        subtype 'ArrayOfSpecialResources',

            as 'ArrayRef[SpecialResource]';

        with 'MooseX::Semantic::Util::TypeConstraintWalker';
        has val => (
            is => 'rw',
            isa => 'ArrayOfSpecialResources',
        );
        1;
    }

    my $b = Bar->new( val => [MooseX::Semantic::Test::Person->new] );
    my $does_resource = sub {my $a= shift;$a->can('does') && $a->does('MooseX::Semantic::Role::Resource'); };

    is ($b->_find_parent_type('val', $does_resource, look_vertically => 1), 'MooseX::Semantic::Test::Person');
    # warn Dumper $does_resource->("MooseX::Semantic::Test::Person");
    # warn Dumper "MooseX::Semantic::Test::Person"->does('MooseX::Semantic::Role::Resource');
    # warn Dumper $b;
    # warn Dumper keys %{$b->meta->get_attribute('val')->type_constraint};
}


&simple_type_walker;
&class_name_finder;
