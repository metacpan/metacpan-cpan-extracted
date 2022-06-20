#!perl
use v5.16;
use strict;
use warnings;
use Test::More;
use File::Spec::Functions qw( catfile );

BEGIN {
    use_ok( 'Pod::Query' ) || print "Bail out!\n";
}

diag( "Testing Pod::Query $Pod::Query::VERSION, Perl $], $^X" );

my @cases = (
    {
        pod_class => "ojo",
        expect    => qr{ \b ojo\.pm $ }x,
    },
    {
        pod_class => "ojo2",
        expect    => qr{ ^ $ }x,    # Empty.
    },
    {
        pod_class => "Mojo::UserAgent",
        expect    => qr{ \b
            @{[ quotemeta catfile(
                    "Mojo",
                    "UserAgent.pm"
                )
            ]}
            $ }x,
    },
);


for my $case ( @cases ) {
    my ( $class, $expect ) = @$case{qw/ pod_class expect /};
    my $got = Pod::Query::_class_to_path( $class ) // "";

    like( $got, $expect, "Correct class for $class" );
}


done_testing( 4 );

