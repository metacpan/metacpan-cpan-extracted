package Root;
use Moxie;

extends 'Moxie::Object';

has '_foo';

sub BUILDARGS : init_args( foo? => _foo );

sub foo { _foo }

1;
