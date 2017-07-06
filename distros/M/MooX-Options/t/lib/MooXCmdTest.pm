package MooXCmdTest;

use strict;
use warnings all => 'FATAL';

use Moo;
use MooX::Cmd;
use MooX::Options
    authors     => 'Celogeek <me@celogeek.com>',
    description => 'This is a test sub command',
    synopsis    => 'This is a test synopsis';

sub execute {
    die "need a sub command !";
}

1;
