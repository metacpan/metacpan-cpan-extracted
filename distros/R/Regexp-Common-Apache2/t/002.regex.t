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
        regex           => q{/John Doe/},
        regpattern      => q{John Doe},
        test            => q{/John Doe/},
    },
    {
        regex           => q{m#John Doe#},
        regpattern      => q{John Doe},
        regsep          => q{#},
        test            => q{m#John Doe#},
    },
    {
        regex           => q{m$John Doe$},
        regpattern      => q{John Doe},
        regsep          => q{$},
        test            => q{m$John Doe$},
    },
    {
        regex           => q{m%John Doe%},
        regpattern      => q{John Doe},
        regsep          => q{%},
        test            => q{m%John Doe%},
    },
    {
        regex           => q{m^John Doe^},
        regpattern      => q{John Doe},
        regsep          => q{^},
        test            => q{m^John Doe^},
    },
    {
        regex           => q{m|John Doe|},
        regpattern      => q{John Doe},
        regsep          => q{|},
        test            => q{m|John Doe|},
    },
    {
        regex           => q{m?John Doe?},
        regpattern      => q{John Doe},
        regsep          => q{?},
        test            => q{m?John Doe?},
    },
    {
        regex           => q{m!John Doe!},
        regpattern      => q{John Doe},
        regsep          => q{!},
        test            => q{m!John Doe!},
    },
    {
        regex           => q{m'John Doe'},
        regpattern      => q{John Doe},
        regsep          => q{'},
        test            => q{m'John Doe'},
    },
    {
        regex           => q{m"John Doe"},
        regpattern      => q{John Doe},
        regsep          => q{"},
        test            => q{m"John Doe"},
    },
    {
        regex           => q{m,John Doe,},
        regpattern      => q{John Doe},
        regsep          => q{,},
        test            => q{m,John Doe,},
    },
    {
        regex           => q{m;John Doe;},
        regpattern      => q{John Doe},
        regsep          => q{;},
        test            => q{m;John Doe;},
    },
    {
        regex           => q{m:John Doe:},
        regpattern      => q{John Doe},
        regsep          => q{:},
        test            => q{m:John Doe:},
    },
    {
        regex           => q{m.John Doe.},
        regpattern      => q{John Doe},
        regsep          => q{.},
        test            => q{m.John Doe.},
    },
    {
        regex           => q{m_John Doe_},
        regpattern      => q{John Doe},
        regsep          => q{_},
        test            => q{m_John Doe_},
    },
    {
        regex           => q{m-John Doe-},
        regpattern      => q{John Doe},
        regsep          => q{-},
        test            => q{m-John Doe-},
    },
    ## Fail
    ## Illegal separaters
    {
        fail        => 1,
        test        => q{*John Doe*},
    },
    
    ## Unbalanced
    {
        fail        => 1,
        test        => q{/John Doe#},
    },
];

my $sub = $ENV{AUTHOR_TESTING} ? \&dump_tests : \&run_tests;
$sub->( $tests,
{
    type => 'Regexp',
    re => $RE{Apache2}{Regexp},
});
