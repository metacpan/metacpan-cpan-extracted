#!perl

package TestRegistry::pages::good;

use strict;
use warnings;
use Apache2::RequestRec ();
use Apache2::RequestIO ();
use Apache2::Const qw(OK);

return 1;

sub handler {
    my $r = shift;
    $r->content_type('text/plain');
    $r->print('good ok');
    return OK;
}
