use Perl6::Form;
use Perl6::Form 'drill';

@data = map [split /[\t\n]+/], <DATA>;
($name, $payment) = drill @data, [], [0..1];

print form
  'Name              Payment (per unit)',
  {under=>"=-\n"},
  '{[[[[[[[[[[[}        {]],]]].[[[}',
  $name,                {lfill=>'*', rfill=>'0'},
				        $payment;

print "\n\n";

print form
  'Name              Payment (per unit)',
  {under=>"=-\n"},
  '{[[[[[[[[[[[}        {*],]]].[[0}',
   $name,               $payment; 

__DATA__
Jones, K.		12.676
Nguyen, T.		1.62
Woo, J.			45615
Zwiky, Z.		19.0003
