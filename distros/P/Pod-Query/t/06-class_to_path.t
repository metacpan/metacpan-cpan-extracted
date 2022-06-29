#!perl
use v5.16;
use strict;
use warnings;
use Test::More tests => 6;
use File::Spec::Functions qw( catfile );
use FindBin               qw( $RealDir );

BEGIN {
    use_ok( 'Pod::Query' ) || print "Bail out!\n";
}

diag( "Testing Pod::Query $Pod::Query::VERSION, Perl $], $^X" );

my $sample_pod = catfile( $RealDir, qw( pod Mojo_UserAgent.pm ) );

ok( -f $sample_pod, "pod file exists" );

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
    {
        pod_class => "$sample_pod",
        expect    => qr{ ^ \Q$sample_pod\E $ }x,    # Empty.
    },
);


for my $case ( @cases ) {
    my ( $class, $expect ) = @$case{qw/ pod_class expect /};
    my $got = Pod::Query->_class_to_path( $class ) // "";

    like( $got, $expect, "Correct class for $class" );
}

