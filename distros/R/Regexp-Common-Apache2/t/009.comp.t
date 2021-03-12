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
        comp            => q{"John" == "Jack"},
        comp_stringcomp => q{"John" == "Jack"},
        name            => q{string comparison},
        test            => q{"John" == "Jack"},
    },
    {
        comp            => q{10 -ne 20},
        comp_integercomp => q{10 -ne 20},
        name            => q{integer comparison},
        test            => q{10 -ne 20},
    },
    {
        comp            => q{-e '/some/folder/file.txt'},
        comp_unary      => q{-e '/some/folder/file.txt'},
        comp_unaryop    => q{e},
        comp_word       => q{'/some/folder/file.txt'},
        name            => q{unary operator},
        test            => q{-e '/some/folder/file.txt'},
    },
    {
        comp            => q{'192.168.2.10' -ipmatch '192.168.2.1/24'},
        comp_binary     => q{'192.168.2.10' -ipmatch '192.168.2.1/24'},
        comp_binaryop   => q{ipmatch},
        comp_worda      => q{'192.168.2.10'},
        comp_wordb      => q{'192.168.2.1/24'},
        name            => q{binary operator},
        test            => q{'192.168.2.10' -ipmatch '192.168.2.1/24'},
    },
    {
        comp            => q{"John" in someListFunc("Some arguments")},
        comp_listfunc   => q{someListFunc("Some arguments")},
        comp_word       => q{"John"},
        comp_word_in_listfunc => q{"John" in someListFunc("Some arguments")},
        name            => q{word in list function},
        test            => q{"John" in someListFunc("Some arguments")},
    },
    {
        comp            => q{"John" =~ /^\w+$/},
        comp_regexp     => q{/^\w+$/},
        comp_regexp_op  => q{=~},
        comp_word       => q{"John"},
        comp_word_in_regexp => q{"John" =~ /^\w+$/},
        name            => q{word =~ reggular expression},
        regex           => q{/^\w+$/},
        regpattern      => q{^\w+$},
        regsep          => q{/},
        test            => q{"John" =~ /^\w+$/},
    },
    {
        comp            => q{"John" in {"Joe", "Peter", "Paul"}},
        comp_list       => q{"Joe", "Peter", "Paul"},
        comp_word       => q{"John"},
        comp_word_in_list => q{"John" in {"Joe", "Peter", "Paul"}},
        name            => q{word in list},
        test            => q{"John" in {"Joe", "Peter", "Paul"}},
    },
    {
        comp            => q{%{HTTP_COOKIE} =~ /lang\%22\%3A\%22([a-zA-Z]+\-[a-zA-Z]+)\%22\%7D;?/},
        comp_regexp     => q{/lang\%22\%3A\%22([a-zA-Z]+\-[a-zA-Z]+)\%22\%7D;?/},
        comp_regexp_op  => q{=~},
        comp_word       => q{%{HTTP_COOKIE}},
        comp_word_in_regexp => q{%{HTTP_COOKIE} =~ /lang\%22\%3A\%22([a-zA-Z]+\-[a-zA-Z]+)\%22\%7D;?/},
        name            => q{word =~ regular expression (2)},
        regex           => q{/lang\%22\%3A\%22([a-zA-Z]+\-[a-zA-Z]+)\%22\%7D;?/},
        regpattern      => q{lang\%22\%3A\%22([a-zA-Z]+\-[a-zA-Z]+)\%22\%7D;?},
        regsep          => q{/},
        test            => q{%{HTTP_COOKIE} =~ /lang\%22\%3A\%22([a-zA-Z]+\-[a-zA-Z]+)\%22\%7D;?/},
    },
    {
        comp            => q{%{HTTP_HOST} == 'example.com'},
        comp_stringcomp => q{%{HTTP_HOST} == 'example.com'},
        name            => q{%{HTTP_HOST} == 'example.com'},
        test            => q{%{HTTP_HOST} == 'example.com'},
    },
    {
        comp            => q{%{QUERY_STRING} =~ /forcetext/},
        comp_regexp     => q{/forcetext/},
        comp_regexp_op  => q{=~},
        comp_word       => q{%{QUERY_STRING}},
        comp_word_in_regexp => q{%{QUERY_STRING} =~ /forcetext/},
        name            => q{%{QUERY_STRING} =~ /forcetext/},
        regex           => q{/forcetext/},
        regpattern      => q{forcetext},
        regsep          => q{/},
        test            => q{%{QUERY_STRING} =~ /forcetext/},
    },
    {
        comp            => q{%{HTTP:X-example-header} in { 'foo', 'bar', 'baz' }},
        comp_list       => q{'foo', 'bar', 'baz'},
        comp_word       => q{%{HTTP:X-example-header}},
        comp_word_in_list => q{%{HTTP:X-example-header} in { 'foo', 'bar', 'baz' }},
        name            => q{%{HTTP:X-example-header} in { 'foo', 'bar', 'baz' }},
        test            => q{%{HTTP:X-example-header} in { 'foo', 'bar', 'baz' }},
    },
    {
        comp            => q{-R '192.168.1.0/24'},
        comp_unary      => q{-R '192.168.1.0/24'},
        comp_unaryop    => q{R},
        comp_word       => q{'192.168.1.0/24'},
        name            => q{-R '192.168.1.0/24'},
        test            => q{-R '192.168.1.0/24'},
    },
    {
        comp            => q{md5('foo') == 'acbd18db4cc2f85cedef654fccc4a4d8'},
        comp_stringcomp => q{md5('foo') == 'acbd18db4cc2f85cedef654fccc4a4d8'},
        name            => q{md5('foo') == 'acbd18db4cc2f85cedef654fccc4a4d8'},
        test            => q{md5('foo') == 'acbd18db4cc2f85cedef654fccc4a4d8'},
    },
    {
        comp            => q{%{REQUEST_URI} =~ m#^/special_path\.php$#},
        comp_regexp     => q{m#^/special_path\.php$#},
        comp_regexp_op  => q{=~},
        comp_word       => q{%{REQUEST_URI}},
        comp_word_in_regexp => q{%{REQUEST_URI} =~ m#^/special_path\.php$#},
        name            => q{%{REQUEST_URI} =~ m#^/special_path\.php$#},
        regex           => q{m#^/special_path\.php$#},
        regpattern      => q{^/special_path\.php$},
        regsep          => q{#},
        test            => q{%{REQUEST_URI} =~ m#^/special_path\.php$#},
    },
    {
        comp            => q{%{REQUEST_STATUS} >= 400},
        comp_stringcomp => q{%{REQUEST_STATUS} >= 400},
        name            => q{%{REQUEST_STATUS} >= 400},
        test            => q{%{REQUEST_STATUS} >= 400},
    },
    {
        comp            => q{%{REQUEST_STATUS} -in {'405','410'}},
        comp_list       => q{'405','410'},
        comp_word       => q{%{REQUEST_STATUS}},
        comp_word_in_list => q{%{REQUEST_STATUS} -in {'405','410'}},
        name            => q{%{REQUEST_STATUS} -in {'405','410'}},
        test            => q{%{REQUEST_STATUS} -in {'405','410'}},
    },
    {
        comp            => q{'192.168.1.10' !-ipmatch '192.168.2.0/24'},
        comp_binary     => q{'192.168.1.10' !-ipmatch '192.168.2.0/24'},
        comp_binary_is_neg => q{!},
        comp_binaryop   => q{ipmatch},
        comp_worda      => q{'192.168.1.10'},
        comp_wordb      => q{'192.168.2.0/24'},
        name            => q{'192.168.1.10' !-ipmatch '192.168.2.0/24'},
        test            => q{'192.168.1.10' !-ipmatch '192.168.2.0/24'},
    },
];

my $sub = $ENV{AUTHOR_TESTING} ? \&dump_tests : \&run_tests;
$sub->( $tests,
{
    type => 'Comparison',
    re => $RE{Apache2}{Comp},
});
