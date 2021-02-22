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
ok( q{%{:10:}} =~ /\{\:$RE{Apache2}{Digits}\:\}/, q{%{:10:} using digits} );

ok( q{%{:10:}} =~ /\%\{\:$RE{Apache2}{Word}\:\}/, q{%{:10:} using word} );

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
];

my $sub = $ENV{AUTHOR_TESTING} ? \&dump_tests : \&run_tests;
$sub->( $tests,
{
    type => 'Variable',
    re => $RE{Apache2}{Variable},
});
