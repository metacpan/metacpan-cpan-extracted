#!perl

package TestRegistry::pages::sub::index;

use strict;
use warnings;
use Apache2::RequestRec ();
use Apache2::RequestIO ();
use Apache2::Const qw(OK);

return 1;

sub handler {
    my($class, $r) = @_;
    $r->content_type('text/plain');
    $r->print('sub index ok');
    return OK;
}
