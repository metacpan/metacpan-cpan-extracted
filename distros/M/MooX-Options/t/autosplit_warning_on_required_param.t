#!perl
#
# This file is part of MooX-Options
#
# This software is copyright (c) 2013 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use t::Test;
use Test::Trap;

{

    package t;
    use strict;
    use warnings;
    use Moo;
    use MooX::Options;

    option 'treq' => (
        is            => 'ro',
        documentation => 'this is mandatory',
        format        => 's@',
        required      => 1,
        autosplit     => ",",
    );

    1;
}

{
    local @ARGV = ('--treq');
    trap { my $opt = t->new_with_options(); };
    like $trap->stderr,   qr/treq is missing/,      'stdout ok';
    unlike $trap->stderr, qr/Use of uninitialized/, 'stderr ok';
}

done_testing;

