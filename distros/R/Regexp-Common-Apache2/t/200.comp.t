#!/usr/local/bin/perl
BEGIN
{
    use Test::More qw( no_plan );
    use_ok( 'Regexp::Common::Apache2' ) || BAIL_OUT( "Unable to load Regexp::Common::Apache2" );
    use lib './lib';
    use Regexp::Common qw( Apache2 );
    require( "./t/functions.pl" ) || BAIL_OUT( "Unable to find library \"functions.pl\"." );
};

my $tests = 
[
    {
        comp            => q{$HTTP_COOKIE = /lang\%22\%3A\%22([a-zA-Z]+\-[a-zA-Z]+)\%22\%7D;?/},
        comp_in_regexp_legacy => q{$HTTP_COOKIE = /lang\%22\%3A\%22([a-zA-Z]+\-[a-zA-Z]+)\%22\%7D;?/},
        comp_regexp     => q{/lang\%22\%3A\%22([a-zA-Z]+\-[a-zA-Z]+)\%22\%7D;?/},
        comp_regexp_op  => q{=},
        comp_word       => q{$HTTP_COOKIE},
        name            => q{word = regular expression},
        test            => q{$HTTP_COOKIE = /lang\%22\%3A\%22([a-zA-Z]+\-[a-zA-Z]+)\%22\%7D;?/},
    },
    {
        comp            => q{${HTTPS} = 'on'},
        comp_binary     => q{${HTTPS} = 'on'},
        comp_binaryop   => q{=},
        comp_worda      => q{${HTTPS}},
        comp_wordb      => q{'on'},
        name            => q{word = 'value'},
        test            => q{${HTTPS} = 'on'},
    },
];

my $sub = $ENV{AUTHOR_TESTING} ? \&dump_tests : \&run_tests;
$sub->( $tests,
{
    type => 'Legacy Comparison',
    re => $RE{Apache2}{LegacyComp},
});
