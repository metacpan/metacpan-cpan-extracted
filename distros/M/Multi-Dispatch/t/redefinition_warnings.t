use 5.022;
use warnings;
use strict;

use Test::More;
BEGIN { plan tests => 10; }

use feature 'lexical_subs';
no warnings 'experimental::lexical_subs';

sub expect_warning {
    my ($expected) = @_;
    $SIG{__WARN__} = sub {
        my ($warning) = @_;
        chomp $warning;
        like $warning, $expected => "Warning: $warning";
    };
}


use Multi::Dispatch;

sub non_multi { return 'non_multi' }

BEGIN { expect_warning qr/\ASubroutine .*? redefined as multi/ }

multi non_multi ()     { return 'multi' }
multi non_multi ($arg) { return 'multi arg' }

BEGIN {
    is non_multi(),      'multi'     => 'non_multi()';
    is non_multi('arg'), 'multi arg' => 'non_multi(arg)';
}


sub lexical { return 'non-multi' }

multi lexical ()     { return 'multi' }
multi lexical ($arg) { return 'multi arg' }


BEGIN {
    my sub lexical { return 'lexical' }
    is lexical(),      'lexical'   =>   'lexical()';
    is lexical('arg'), 'lexical'   =>   'lexical(arg)';
}


BEGIN { expect_warning qr/\ASubroutine .*? redefined at/ }

sub non_multi {}


BEGIN { expect_warning qr/\ASubroutine .*? redefined as multi/ }
no warnings 'Multi::Dispatch::noncontiguous';

multi non_multi ($arg1, $arg2)  { return 'multi 2 arg' }
multi non_multi ($arg, @etc)    { return 'multi arg slurpy' }

multimethod mm () {};

{
    package Elsewhere;

    BEGIN { *mm = \&main::mm }

    BEGIN { ::expect_warning qr/\AMultimethod mm\(\) \[imported from main\] redefined as multimethod mm\(\) at/ }

    multimethod mm () {};
}

{
    package Otherwise;

    BEGIN { *non_multi = \&main::non_multi }

    BEGIN { ::expect_warning qr/\AMulti non_multi\(\) \[imported from main\] redefined as multi non_multi\(\) at/ }

    multi       non_multi () {}
}

{
    package Silent;
    no warnings 'redefine';

    sub foo {}

    BEGIN { ::expect_warning qr/(?!)/ }

    multi foo () {}
}


done_testing();
