use strict;
use warnings;
package MooyDirty;

use Moo;
use File::Spec::Functions 'catdir';

sub stuff {}

use constant CAN => [ qw(stuff catdir meta has with) ];
use constant CANT => [ ];
use constant DIRTY => [ qw(catdir has with) ];

1;
