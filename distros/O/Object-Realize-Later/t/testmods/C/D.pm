package C::D;
use base 'C';

use Object::Realize::Later
  ( becomes            => 'A::B'
  , realize            => 'load'
  , warn_realization   => 1
  , warn_realize_again => 1
  );

sub load() { bless {}, 'A::B' }
sub c_d()  {'c_d'}

1;
