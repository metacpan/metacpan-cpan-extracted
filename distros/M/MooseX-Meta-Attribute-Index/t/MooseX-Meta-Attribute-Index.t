
use Test::More tests => 12;        
# BEGIN { diag 'MooseX::Meta::Attribute::Index'; }


##########
package App;
    use Test::More;

    BEGIN {
        use_ok( 'Moose' );
        ok( with('MooseX::Meta::Attribute::Index'), "with OK" );
    }


    has attr_1 => (
                     traits  => [ qw/Index/ ],
                     is      => 'rw'  ,
                     isa     => 'Str' ,
                     index=> 1 ,
    );

    has attr_2 => ( 
                     traits  => [ qw/Index/ ],
                     is      => 'rw'  ,
                     isa     => 'Int' ,
                     index=> 3
    );   

    has attr_3 => (
                    is      => 'rw'     ,
                    isa     => 'Str'    ,
                    default => 'This is not indexed' ,
                    required=> 1
    );



##########
package main;


    my $app = App->new( attr_1 => "foo", attr_2 => 42 );    

    isa_ok( $app, "App" );

    ok( $app->meta->does_role( 'MooseX::Meta::Attribute::Index' ), 
            'Class does role MooseX::Meta::Attribute::Index' 
    ); 

    ok( $app->attr_1 eq "foo",  "Attribute 1" );
    ok( $app->attr_2 == 42, "Attribute 2" );

    ok( $app->get_attribute_index( "attr_1" ) == 1, "get_attibute_index 1" ) ;
    ok( $app->get_attribute_index( "attr_2" ) == 3, "get_attibute_index 2" ) ;

    ok( 
        $app->get_attribute_by_index(1)->index == 1, 
        "get_attribute_by_index 1" 
    );
    ok( 
        $app->get_attribute_by_index(3)->index == 3, 
        "get_attribute_by_index 2" 
    );

    ok( 
        $app->get_attribute_name_by_index(1) eq 'attr_1', 
        "get_attribute_name_by_index 1"
    ); 
    ok( 
        $app->get_attribute_name_by_index(3) eq 'attr_2',
        "get_attribute_name_by_index 3"
    ); 



