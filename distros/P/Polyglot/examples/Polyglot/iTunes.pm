package Polyglot::iTunes;

use vars qw($VERSION);

$VERSION = 0.10;

print "Loaded " . __PACKAGE__ . " $VERSION\n";

package Polyglot;

use Mac::iTunes;

my $iTunes = Mac::iTunes->controller;

$polyglot->add_action( 'P', sub { $iTunes->play }     );
$polyglot->add_action( 'S', sub { $iTunes->stop }     );
$polyglot->add_action( '<', sub { $iTunes->previous } );
$polyglot->add_action( '>', sub { $iTunes->next }     );
$polyglot->add_action( 'D', sub { sleep $_[1] }       );


1;