#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 3;

BEGIN {
    use_ok('Plack::Handler::H2');
    use_ok('Plack::Handler::H2::Writer');
}

can_ok('Plack::Handler::H2', qw(new run _generate_self_signed_cert _responder));
