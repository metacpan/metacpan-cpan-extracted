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

local $ENV{TEST_FORCE_COLUMN_SIZE} = 78;

{

    package t1;
    use Moo;
    use MooX::Options;

    option 'first' => (
        is            => 'ro',
        documentation => 'first option',
        order         => 1,
    );

    option 'second' => (
        is            => 'ro',
        documentation => 'second option',
        order         => 2,
    );

    option 'third' => (
        is            => 'ro',
        documentation => 'third option',
        order         => 3,
    );

    option 'fourth' => (
        is            => 'ro',
        documentation => 'fourth option',
        order         => 4,
    );

    1;
}

{

    package t2;
    use Moo;
    use MooX::Options;

    option 'first' => (
        is            => 'ro',
        documentation => 'first option',
    );

    option 'second' => (
        is            => 'ro',
        documentation => 'second option',
    );

    option 'third' => (
        is            => 'ro',
        documentation => 'third option',
    );

    option 'fourth' => (
        is            => 'ro',
        documentation => 'fourth option',
    );

    1;
}

{

    package t3;
    use Moo;
    use MooX::Options;

    option 'first' => (
        is            => 'ro',
        documentation => 'first option',
        order         => 1,
    );

    option 'second' => (
        is            => 'ro',
        documentation => 'second option',
        order         => 2,
    );

    option 'third' => (
        is            => 'ro',
        documentation => 'third option',
    );

    option 'fourth' => (
        is            => 'ro',
        documentation => 'fourth option',
    );

    1;
}

{
    my $opt = t1->new_with_options;
    trap { $opt->options_usage };
    like $trap->stdout, qr/first.+second.+third.+fourth/ms,
        'order work w/ order attribute';
}

{
    my $opt = t2->new_with_options;
    trap { $opt->options_usage };
    like $trap->stdout, qr/first.+fourth.+second.+third/ms,
        'order work w/o order attribute';
}

{
    my $opt = t3->new_with_options;
    trap { $opt->options_usage };
    like $trap->stdout, qr/fourth.+third.+first.+second/ms,
        'order work w/ mixed mode';
}

done_testing;
