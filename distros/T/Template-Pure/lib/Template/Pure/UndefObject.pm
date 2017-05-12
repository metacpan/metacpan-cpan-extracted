package Template::Pure::UndefObject;
 
use strict;
use warnings;
use Scalar::Util 'blessed';
 
use overload
  'bool' => sub { 0 },
  '!' => sub { 1 },
  q{""} => sub { undef },
  'fallback' => 1;
 
sub can { 1 } # probably evil...
sub AUTOLOAD { shift }
 
sub maybe {
  blessed $_[0] ? $_[0] : do {
    my ($class, $obj) = @_;
    defined $obj ? $obj :
      bless {}, $class };
}
 
1;
