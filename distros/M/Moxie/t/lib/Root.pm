package Root;
use Moxie;

extends 'Moxie::Object';

has 'foo';

my sub _foo : private(foo);

sub foo { _foo }

1;
