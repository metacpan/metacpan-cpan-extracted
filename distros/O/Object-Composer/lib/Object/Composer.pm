package Object::Composer;

use strict;
use warnings;
use Carp;


our $VERSION = q(0.0.2);


sub import {
  no strict 'refs';

  shift;

  my $caller_package = caller( );
  *{"$caller_package\::load"} = \&{ __PACKAGE__ . '::load' };
}


sub load {
  my ( @all ) = @_;

  croak 'No arguments given, not sure what you want me to do?' 
    unless @all;

  # Getting called as a Class Method / Object Instance method
  # ignore the first argument
  shift if $all[0] eq __PACKAGE__ || $all[0]->isa( __PACKAGE__ ); 

  my $obj;
  my ( $package, @args ) = @_;
 
  my $code = <<USE;
    use $package;
USE

  eval $code;
  $obj = $package->new( @args ); 

  croak "There was an error loading: $@" if $@;
  
  $obj;
}


'done';


__END__

=head1 NAME

Object::Composer - Simple helper to load classes automatically and instantiate them

=head1 SYNOPSIS

  use Object::Composer;

  my $neo = load 'My::Person', name => 'Neo', job => 'Hacker', age => 'NA';

  # OR ( if you don't want import functions into your space )

  use Object::Composer ();

  my $morpheus = Object::Composer->load( 'My::Person', name => 'morpheus', job => 'warrior', age => 'NA' );

  # OR ( You can call it as Class Method or as Function in Object::Composer's namespace )

  my $morpheus = Object::Composer::load( 'My::Person', name => 'morpheus', job => 'warrior', age => 'NA' );


=head1 DESCRIPTION

This is a simple helper class that helps loading class automatically, instantiate an object and return it. 
It assumes that 'new' method is already defined in the loaded class, which is what it calls to instantiate the object.

croaks if theres any error while loading or instantiating.


=head2 C<< load $class, @args >>

This is the only function / method defined. It loads the package / module, calls "new" on the class with arguments you pass, and returns the instantiated object.

  $obj = load 'LWP::UserAgent', agent => 'My Own Secret Agent';

  # OR

  $obj = Object::Composer->load( 'HTML::TreeBuilder' );



=head1 AUTHOR

Venkatakrishnan Ganesh <gvenkat@cpan.org>

=head1 COPYRIGHT AND LICENSE

This library is free software and may be distributed under the same terms
as perl itself.

=cut
