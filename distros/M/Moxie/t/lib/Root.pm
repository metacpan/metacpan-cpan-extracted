package Root;
use Moxie;

extends 'Moxie::Object';

has '_foo';

my sub _foo : private;

sub BUILDARGS : init_args( foo? => _foo );

sub foo { _foo }

1;
