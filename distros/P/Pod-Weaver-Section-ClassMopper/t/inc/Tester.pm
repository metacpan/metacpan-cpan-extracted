package Tester;
use Moose;

has 'testattr1' => ( 
   is => 'rw',
   isa => 'Str'
);

has 'testattr2' => ( 
   is => 'ro',
   isa => 'Num',
   documentation => 'This is a documentation option test.  It is a string.  With some L<links>'
 );

 sub method1 { }

sub _private_method { }

__PACKAGE__->meta->make_immutable;

=pod

=cut

