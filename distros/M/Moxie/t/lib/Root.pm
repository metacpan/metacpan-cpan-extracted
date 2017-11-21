package Root;
use Moxie
    traits => [':experimental'];

extends 'Moxie::Object';

has '_foo';

my sub _foo : private;

sub BUILDARGS : strict( foo? => _foo );

sub foo { _foo }

1;
