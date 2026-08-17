package Punk::Command::Fakecmd;

# t/57's plugin-seam fixture: bin/punk probes Punk::Command::<Ucfirst> on an
# unknown command, and loading the module IS the registration.

use strict;
use warnings;
use Punk::Command ();

Punk::Command->register(fakecmd => {
    abstract => 'a test fixture',
    hidden   => 1,
    options  => [ { spec => 'shout', doc => 'upper case' } ],
    code     => sub {
        my ($opt) = @_;
        print $opt->{shout} ? "FAKE\n" : "fake\n";
        return 42;
    },
}, __PACKAGE__);

1;
