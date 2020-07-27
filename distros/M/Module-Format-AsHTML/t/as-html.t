#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 3;

use Module::Format::AsHTML ();

{
    my $cpan = Module::Format::AsHTML->new();

    # TEST
    ok( $cpan, "object was instantiated" );

    # TEST
    is( $cpan->homepage( { who => "shlomif" } ),
        "https://metacpan.org/author/SHLOMIF", "homepage" );

    # TEST
    is(
        $cpan->self_dist( { d => "Module-Format" } ),
qq{<a href="https://metacpan.org/release/Module-Format">Module-Format</a>},
        "homepage"
    );
}
