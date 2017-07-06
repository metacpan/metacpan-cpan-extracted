#!perl
use strict;
use warnings all => 'FATAL';
use Test::More;
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

