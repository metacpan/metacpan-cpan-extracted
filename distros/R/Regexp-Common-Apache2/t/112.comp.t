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
        comp            => q{md5('foo') == replace('md5:XXXd18db4cc2f85cedef654fccc4a4d8', 'md5:XXX', 'acb')},
        comp_stringcomp => q{md5('foo') == replace('md5:XXXd18db4cc2f85cedef654fccc4a4d8', 'md5:XXX', 'acb')},
        name            => q{md5('foo') == replace('md5:XXXd18db4cc2f85cedef654fccc4a4d8', 'md5:XXX', 'acb')},
        test            => q{md5('foo') == replace('md5:XXXd18db4cc2f85cedef654fccc4a4d8', 'md5:XXX', 'acb')},
    },
    {
        comp            => q{%{REMOTE_ADDR} -in split(s/.*?IP Address:([^,]+)/$1/, PeerExtList('subjectAltName'))},
        comp_listfunc   => q{split(s/.*?IP Address:([^,]+)/$1/, PeerExtList('subjectAltName'))},
        comp_word       => q{%{REMOTE_ADDR}},
        comp_word_in_listfunc => q{%{REMOTE_ADDR} -in split(s/.*?IP Address:([^,]+)/$1/, PeerExtList('subjectAltName'))},
        name            => q{in function list},
        test            => q{%{REMOTE_ADDR} -in split(s/.*?IP Address:([^,]+)/$1/, PeerExtList('subjectAltName'))},
    },
];

my $sub = $ENV{AUTHOR_TESTING} ? \&dump_tests : \&run_tests;
$sub->( $tests,
{
    type => 'Comparison (Trunk)',
    re => $RE{Apache2}{TrunkComp},
});
