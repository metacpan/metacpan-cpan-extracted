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

    option 'hero' => (
        is     => 'ro',
        doc    => 'this is mandatory',
        format => 's@',
        isa    => sub { die "boop\n" },
    );

    1;
}

{
    local @ARGV = (qw/--hero batman/);
    trap { my $opt = t->new_with_options(); };
    like $trap->stderr, qr/^boop/, 'stdout ok';
    like $trap->stderr, qr/USAGE/, 'stderr ok';
}

done_testing;

