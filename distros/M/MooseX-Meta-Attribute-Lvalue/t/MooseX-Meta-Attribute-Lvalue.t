#!perl 

use Test::More tests => 7;

BEGIN {
	use_ok( 'MooseX::Meta::Attribute::Lvalue' );
}

diag( "Testing MooseX::Meta::Attribute::Lvalue $MooseX::Meta::Attribute::Lvalue::VERSION, Perl $], $^X" );


{
    package App;
        use Moose;
        with 'MooseX::Meta::Attribute::Lvalue';

            has 'name' => ( 
                is => 'rw', isa => 'Str' , 
                traits => [ 'Lvalue' ] , 
            );


            has 'count' => (
                is => 'rw', isa => 'Int' ,
                default => 0 ,
                traits => [ 'Lvalue' ] ,
            );


            has 'sign' => ( 
                is => 'rw' , 
                isa => 'Str', 
                # traits => [ 'Lvalue' ]  # This lacks the Lvalue trait
            );

}

package main;
  my $app = App->new( name => 'frank', sign => 'pisces' );
  

  isa_ok( $app, "App" );
  
# DOES ROLES
  ok( $app->meta->get_attribute( 'name' )->does( 'Lvalue' ), "Does Lvalue" );
  ok( $app->meta->get_attribute( 'count' )->does( 'Lvalue' ), "Attribute 'count' does role 'Lvalue'" );
  ok( $app->meta->get_attribute( 'sign' )->does( 'Lvalue' ) == 0, "Doesn't  Lvalue" );

  eval { $app->sign = "aries" };   # lvalue is 0, does not get changed
  ok( $app->sign eq "pisces", "Normal rw attribute" );  
  
  $app->name = "Ralph" ;
  ok( $app->name eq "Ralph", "Lvalue attribute"  );
  
  
