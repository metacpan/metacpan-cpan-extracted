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
        name            => q{string comparison},
        stringcomp      => q{"John" == "Jack"},
        stringcomp_op   => q{==},
        stringcomp_worda => q{"John"},
        stringcomp_wordb => q{"Jack"},
        test            => q{"John" == "Jack"},
    },
    {
        name            => q{%{HTTP_HOST} == 'example.com'},
        stringcomp      => q{%{HTTP_HOST} == 'example.com'},
        stringcomp_op   => q{==},
        stringcomp_worda => q{%{HTTP_HOST}},
        stringcomp_wordb => q{'example.com'},
        test            => q{%{HTTP_HOST} == 'example.com'},
    },
    {
        name            => q{md5('foo') == 'acbd18db4cc2f85cedef654fccc4a4d8'},
        stringcomp      => q{md5('foo') == 'acbd18db4cc2f85cedef654fccc4a4d8'},
        stringcomp_op   => q{==},
        stringcomp_worda => q{md5('foo')},
        stringcomp_wordb => q{'acbd18db4cc2f85cedef654fccc4a4d8'},
        test            => q{md5('foo') == 'acbd18db4cc2f85cedef654fccc4a4d8'},
    },
    {
        name            => q{%{REQUEST_STATUS} >= 400},
        stringcomp      => q{%{REQUEST_STATUS} >= 400},
        stringcomp_op   => q{>=},
        stringcomp_worda => q{%{REQUEST_STATUS}},
        stringcomp_wordb => 400,
        test            => q{%{REQUEST_STATUS} >= 400},
    },
];

my $sub = $ENV{AUTHOR_TESTING} ? \&dump_tests : \&run_tests;
$sub->( $tests,
{
    type => 'String Comparison',
    re => $RE{Apache2}{StringComp},
});
