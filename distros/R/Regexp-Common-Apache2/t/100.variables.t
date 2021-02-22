#!/usr/local/bin/perl
BEGIN
{
    use Test::More qw( no_plan );
    use_ok( 'Regexp::Common::Apache2' ) || BAIL_OUT( "Unable to load Regexp::Common::Apache2" );
    use lib './lib';
    use Regexp::Common qw( Apache2 );
    require( "./t/functions.pl" ) || BAIL_OUT( "Unable to find library \"functions.pl\"." );
};

# eval( q{use re 'eval'} ) if( $ENV{AUTHOR_TESTING} );
use re 'eval';

#ok( q{%{:10:}} =~ /\%\{\:\d+\:\}/, q{%{:10:}} );
ok( q{%{:10:}} =~ /\{\:$RE{Apache2}{TrunkDigits}\:\}/, q{%{:10:} using digits} );

ok( q{%{:10:}} =~ /\%\{\:$RE{Apache2}{TrunkWord}\:\}/, q{%{:10:} using word} );

ok( q{%{:10:}} =~ /$RE{Apache2}{TrunkVariable}/, q{%{:10:} using variable} );

my $tests = 
[
    {
        name            => q{simple variable},
        test            => q{%{REQUEST_URI}},
        variable        => q{%{REQUEST_URI}},
        varname         => q{REQUEST_URI},
    },
    {
        name            => q{function, arguments},
        test            => q{%{tolower:SomeValue}},
        var_func_args   => q{SomeValue},
        var_func_name   => q{tolower},
        variable        => q{%{tolower:SomeValue}},
    },
    {
        name            => q{word -> digit},
        test            => q{%{:10:}},
        var_word        => q{10},
        variable        => q{%{:10:}},
    },
    {
        name            => q{single quote word},
        test            => q{%{:'Hello':}},
        var_word        => q{'Hello'},
        variable        => q{%{:'Hello':}},
    },
    {
        name            => q{double quote word},
        test            => q{%{:"Hello":}},
        var_word        => q{"Hello"},
        variable        => q{%{:"Hello":}},
    },
    {
        name            => q{dot separated word},
        test            => q{%{:"my"."word":}},
        var_word        => q{"my"."word"},
        variable        => q{%{:"my"."word":}},
    },
    {
        name            => q{dot separated word mixed quotes},
        test            => q{%{:"my".'word':}},
        var_word        => q{"my".'word'},
        variable        => q{%{:"my".'word':}},
    },
    {
        name            => q{substitution within},
        test            => q{%{:sub(s/\w+/Paul/g,"John"):}},
        var_word        => q{sub(s/\w+/Paul/g,"John")},
        variable        => q{%{:sub(s/\w+/Paul/g,"John"):}},
    },
    {
        name            => q{word -> join -> split},
        test            => q{%{:join(split(/\w+/,"John Doe")):}},
        var_word        => q{join(split(/\w+/,"John Doe"))},
        variable        => q{%{:join(split(/\w+/,"John Doe")):}},
    },
    {
        name            => q{word -> join -> words},
        test            => q{%{:join({"John", "Doe"}):}},
        var_word        => q{join({"John", "Doe"})},
        variable        => q{%{:join({"John", "Doe"}):}},
    },
    {
        name            => q{word -> join -> words (variant)},
        test            => q{%{:join(({"John", "Doe"})):}},
        var_word        => q{join(({"John", "Doe"}))},
        variable        => q{%{:join(({"John", "Doe"})):}},
    },
    {
        name            => q{word -> join split with string},
        test            => q{%{:join(split(/\w+/,"John Doe"), "|"):}},
        var_word        => q{join(split(/\w+/,"John Doe"), "|")},
        variable        => q{%{:join(split(/\w+/,"John Doe"), "|"):}},
    },
    {
        name            => q{condition within},
        test            => q{%{:1:}},
        var_cond        => q{1},
        variable        => q{%{:1:}},
    },
    {
        name            => q{regular expression back reference},
        test            => q{$1},
        var_backref     => q{$1},
        variable        => q{$1},
    },
];

my $sub = $ENV{AUTHOR_TESTING} ? \&dump_tests : \&run_tests;
$sub->( $tests,
{
    type => 'Variable (Trunk)',
    re => $RE{Apache2}{TrunkVariable},
});
