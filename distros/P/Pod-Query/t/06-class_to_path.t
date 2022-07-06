#!perl
use v5.16;
use strict;
use warnings;
use Test::More tests => 6;
use File::Spec::Functions qw( catfile catdir );
use FindBin               qw( $RealDir );
use lib catdir( $RealDir, "cpan" );

BEGIN {
    use_ok( 'Pod::Query' ) || print "Bail out!\n";
}

diag( "Testing Pod::Query $Pod::Query::VERSION, Perl $], $^X" );

my $sample_pod        = catfile( $RealDir, qw( cpan Mojo UserAgent.pm ) );
my $windows_safe_path = $sample_pod; # =~ s&(\\)&\\$1&gr;

ok( -f $sample_pod, "pod file exists: $sample_pod" );

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
        expect    => qr{ ^ \Q$windows_safe_path\E $ }x,    # Empty.
    },
);


for my $case ( @cases ) {
    my ( $class, $expect ) = @$case{qw/ pod_class expect /};
    my $got = Pod::Query->_class_to_path( $class ) // "";

    like( $got, $expect, "Correct class for $class" );
}

