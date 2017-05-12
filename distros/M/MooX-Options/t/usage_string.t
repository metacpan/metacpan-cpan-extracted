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
    use MooX::Options usage_string => 'usage: myprogram <hi> %o';

    option 'hero' => (
        is     => 'ro',
        doc    => 'this is mandatory',
        format => 's@',
    );

    1;
}

{
    local @ARGV = (qw/--bad-option/);
    trap { my $opt = t->new_with_options(); };
    like $trap->stderr,
        qr/usage: myprogram <hi> \[-h\] \[long options/,
        'stderr has correct usage';
}

done_testing;

