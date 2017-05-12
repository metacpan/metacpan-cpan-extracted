use strict;
use warnings;
use Test::More;
use Test::Fatal;

use lib 't/lib';

{
    package TestClass;
    use Moose;
    use MooseX::Method::Signatures;

    use aliased 'My::Annoyingly::Long::Name::Space', 'Shortcut';

    ::is(::exception { method alias_sig (Shortcut $affe) { } },
        undef, 'method with aliased type constraint compiles');
}

my $o = TestClass->new;
my $affe = My::Annoyingly::Long::Name::Space->new;

is(exception {
    $o->alias_sig($affe);
}, undef, 'calling method with aliased type constraint');

done_testing;
