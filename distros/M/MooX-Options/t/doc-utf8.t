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
use Carp;
use FindBin qw/$RealBin/;
use Try::Tiny;

local $ENV{TEST_FORCE_COLUMN_SIZE} = 78;

{

    package t;
    use Moo;
    use MooX::Options;

    option 't' => (
        is            => 'ro',
        documentation => 'this is a test with utf8 : ça marche héhé !',
    );

    1;
}

{
    my $opt = t->new_with_options;

    trap { $opt->options_usage };
    like $trap->stdout,
        qr/\s+\-t\s+this\sis\sa\stest\swith\sutf8\s:\sça\smarche\shéhé\s\!/x,
        'documentation work';

    trap { $opt->options_help };
    like $trap->stdout,
        qr/\s+\-t:\n\s+this\sis\sa\stest\swith\sutf8\s:\sça\smarche\shéhé\s\!/x,
        'documentation work';
}

done_testing;
