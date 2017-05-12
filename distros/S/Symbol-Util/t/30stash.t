#!/usr/bin/perl

use strict;
use warnings;

use Carp ();

$SIG{__WARN__} = sub { local $Carp::CarpLevel = 1; Carp::confess("Warning: ", @_) };

use Test::More tests => 2;

use Symbol::Util 'stash';

{
    package Symbol::Util::Test30;
    no warnings 'once';
    sub function { "function" };
    our $scalar = "scalar";
};

is_deeply( [ sort keys %{stash("Symbol::Util::Test30")} ], [ qw( BEGIN function scalar ) ], 'stash("Symbol::Util::Test30")' );

is_deeply( [ sort keys %{stash("Symbol::Util::Test30::NotExists")} ], [], 'stash("Symbol::Util::Test30::NotExists")' );
