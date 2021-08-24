use warnings;
use strict;

use Test::More;

use Script::Singleton glue => 'TEST';

{
    my $w;

    local $SIG{__WARN__} = sub { $w = shift; };

    my $second_proc = `$^X t/10-no_warn.t`;

    is $second_proc, '', "no warnings spewed if warn not set";
}

done_testing;
