#!/usr/bin/env perl

package t::anyevent;

use strict;
use warnings;
use autodie;

use FindBin;
use lib "$FindBin::Bin/lib";

use parent qw( EventTest );

__PACKAGE__->run();

use constant _BACKEND => 'AnyEvent';

sub _REQUIRE {
    require AnyEvent;
}

sub _RESOLVE {
    my ($class, $promise) = @_;

    my $cv = AnyEvent->condvar();
    $promise->catch( sub {} )->finally($cv);
    $cv->recv();
}
