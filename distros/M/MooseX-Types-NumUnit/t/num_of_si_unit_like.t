package MyTest;

use Moose;
use MooseX::Types::NumUnit qw/num_of_si_unit_like/;

has 'length' => ( isa => num_of_si_unit_like('ft'), is => 'rw', required => 1 );

no Moose;
__PACKAGE__->meta->make_immutable;


package main;

use Test::More;

my $thingy = MyTest->new( length => '100 ft' );

is ($thingy->length, 30.48, 'Simple number converts on coersion');

{
  my $bad_length = '1 s';

  my $error;
  local $SIG{__WARN__} = sub { 
    my $in = shift; 
    if ($in =~ /$bad_length/) { 
      $error = $in 
    } else { 
      warn $in 
    } 
  };

  $thingy->length( $bad_length );
  ok ($error, 'Failed unit match warns' );
  is ($thingy->length, 0, 'Failed unit match results in zero');
}

done_testing;

