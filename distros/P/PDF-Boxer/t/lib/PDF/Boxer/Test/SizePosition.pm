package PDF::Boxer::Test::SizePosition;
use Moose;
has 'margin'   => ( isa => 'ArrayRef', is => 'ro', default => sub{ [0,0,0,0] } );
has 'border'   => ( isa => 'ArrayRef', is => 'ro', default => sub{ [0,0,0,0] } );
has 'padding'  => ( isa => 'ArrayRef', is => 'ro', default => sub{ [0,0,0,0] } );
has 'children'  => ( isa => 'ArrayRef', is => 'rw', default => sub{ [] } );

with 'PDF::Boxer::Role::SizePosition';


1;
