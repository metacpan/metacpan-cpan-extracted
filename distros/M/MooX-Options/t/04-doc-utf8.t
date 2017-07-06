#!perl
use strict;
use warnings all => 'FATAL';
use Test::More;
use Test::Trap;

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
