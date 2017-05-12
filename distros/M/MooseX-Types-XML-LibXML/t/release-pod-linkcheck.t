#!perl
#
# This file is part of MooseX-Types-XML-LibXML
#
# This software is copyright (c) 2011 by GSI Commerce.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use utf8;
use Modern::Perl;    ## no critic (UselessNoCritic,RequireExplicitPackage)

BEGIN {
    unless ( $ENV{RELEASE_TESTING} ) {
        require Test::More;
        Test::More::plan(
            skip_all => 'these tests are for release candidate testing' );
    }
}

use strict;
use warnings;
use Test::More;

foreach my $env_skip (
    qw(
    SKIP_POD_LINKCHECK
    )
    )
{
    plan skip_all => "\$ENV{$env_skip} is set, skipping"
        if $ENV{$env_skip};
}

eval "use Test::Pod::LinkCheck";
if ($@) {
    plan skip_all => 'Test::Pod::LinkCheck required for testing POD';
}
else {
    Test::Pod::LinkCheck->new->all_pod_ok;
}
