use strict;
use warnings;
use ExtUtils::MakeMaker;

eval 'use ExtUtils::MakeMaker::Coverage';
warn "Optional ExtUtils::MakeMaker::Coverage not available\n" if $@;

my %EXE = (
    'tap2tet' => {
        PREREQ_PM => {
            'Getopt::Long' => '2.34',
            'Pod::Usage'   => '1.12',
        },
        EXE_FILES => ['bin/tap2tet'],
    }
);

my %ARGS = (
    NAME          => 'TAP::Convert::TET',
    AUTHOR        => 'Andy Armstrong <andy@hexten.net>',
    LICENSE       => 'perl',
    VERSION_FROM  => 'lib/TAP/Convert/TET.pm',
    ABSTRACT_FROM => 'lib/TAP/Convert/TET.pm',
    PL_FILES      => {},
    PREREQ_PM     => {
        'Test::More'  => 0,
        'version'     => 0,
        'TAP::Parser' => 'v0.51',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'TAP-Convert-TET-*' },
);

$ARGS{SIGN} = 1 if MM->can( 'signature_target' );

while ( my ( $exe, $spec ) = each %EXE ) {
    my $yn = prompt( "Install $exe script?", "N" );
    if ( $yn =~ /^y/i ) {
        while ( my ( $key, $val ) = each %$spec ) {
            if ( ref $val eq 'HASH' ) {
                $ARGS{$key} = { %{ $ARGS{$key} || {} }, %$val };
            }
            elsif ( ref $val eq 'ARRAY' ) {
                push @{ $ARGS{$key} }, @$val;
            }
            else {
                die "Can't merge $key: value not handled\n";
            }
        }
    }
}

WriteMakefile( %ARGS );
