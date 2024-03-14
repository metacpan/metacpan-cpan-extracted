use strict; use warnings;
package MockPSGIBodyFH;
sub getline { $_[0][ ++$_[0][0] ] }
sub close { $_[0][0] = 0; 1 }
sub new { my ( $class, $f ) = ( shift, shift ); bless [ 0, @_ ? @_ : $f ], $class }
1;
