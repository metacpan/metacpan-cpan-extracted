#!perl
use strict;
use warnings FATAL => 'all';

use Test::More tests => 1;

use Switch::Plain;

sub context {
    wantarray ? 'list' : 'scalar'
}

my $t = 'scrutinee in scalar context';
sswitch (context) {
    case 'scalar': { pass $t; }
    case 'list':   { fail $t; }
    default:       { fail "wtf? [$_]"; }
}
