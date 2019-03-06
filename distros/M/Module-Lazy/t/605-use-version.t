#!perl

use strict;
use warnings;
use Test::More;

use FindBin qw($Bin);
use lib "$Bin/lib";

use Module::Lazy;
Module::Lazy->import( "Module::Lazy::_::test::subclass" );

my $ok = eval "use Module::Lazy::_::test::subclass 1; 1"; ## no critic
is $@, '', "no error thrown";
is $ok, 1, "eval successful";

Module::Lazy::_::test::subclass->new;

is( $Module::Lazy::_::test::subclass::VERSION, 3.14, "module inflated by use");

is_deeply [ @Module::Lazy::_::test::subclass::ISA ]
    , [qw[Module::Lazy::_::test::sample]]
    , "isa preserved";

done_testing;
