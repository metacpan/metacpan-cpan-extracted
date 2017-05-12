#!/usr/bin/env perl
#
# This file is part of POE-Component-Client-MPD
#
# This software is copyright (c) 2007 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
#

use warnings;
use strict;

use FindBin qw{ $Bin };
use lib "$Bin/../lib";

use POE;
use POE::Component::Client::MPD;

POE::Component::Client::MPD->spawn( {alias => 'mpd'} );
POE::Session->create(
    inline_states => {
        _start     => \&start,
        _stop      => sub { print "bye-bye\n"; },
        mpd_result => \&result,
    }
);
POE::Kernel->run;
exit;



sub start {
    my $k = $_[KERNEL];
    $k->alias_set('client'); # increment refcount
    $k->post( 'mpd', 'coll:all_files' );
}

sub result {
    print "yeah!\n";
}

