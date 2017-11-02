package Root;
use Moxie;

extends 'Moxie::Object';

has '_foo';

my sub _foo : private;

sub BUILDARGS : init( foo? => _foo );

sub foo { _foo }

1;
