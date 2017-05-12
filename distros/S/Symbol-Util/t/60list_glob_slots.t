#!/usr/bin/perl

use strict;
use warnings;

use Carp ();

$SIG{__WARN__} = sub { local $Carp::CarpLevel = 1; Carp::confess("Warning: ", @_) };

use Test::More tests => 5;

use Symbol::Util 'list_glob_slots';

{
    package Symbol::Util::Test60;
    no warnings 'once';
    open FOO, __FILE__ or die $!;
    *FOO = sub { "code" };
    our $FOO = "scalar";
    our @FOO = ("array");
    our %FOO = ("hash" => 1);
};

{
    my @slots = list_glob_slots("Symbol::Util::Test60::FOO");
    is_deeply( [ sort @slots ], [ qw( ARRAY CODE HASH IO SCALAR ) ], 'list_glob_slots("Symbol::Util::Test60::FOO")' );
};

{
    package Symbol::Util::Test60;
    no warnings 'once';
    *BAR = sub { "code" };
};

{
    my @slots = list_glob_slots("Symbol::Util::Test60::BAR");
    is_deeply( [ sort @slots ], [ qw( CODE ) ], 'list_glob_slots("Symbol::Util::Test60::BAR")' );
};

{
    package Symbol::Util::Test60;
    my @slots = Symbol::Util::list_glob_slots("BAR");
    Test::More::is_deeply( [ sort @slots ], [ qw( CODE ) ], 'Symbol::Util::list_glob_slots("BAR")' );
};

{
    my @slots = list_glob_slots("Symbol::Util::Test60::BAZ");
    is_deeply( [ sort @slots ], [ qw( ) ], 'list_glob_slots("Symbol::Util::Test60::BAZ")' );
};

{
    package Symbol::Util::Test60;
    no warnings 'once';
    our $NULL = undef;
};

{
    my @slots = list_glob_slots("Symbol::Util::Test60::NULL");
    is_deeply( [ sort @slots ], [ qw( ) ], 'list_glob_slots("Symbol::Util::Test60::NULL")' );
};
