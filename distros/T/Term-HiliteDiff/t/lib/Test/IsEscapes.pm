package Test::IsEscapes;
use strict;
use vars qw( @EXPORT_OK );

use Test::More ();
use Exporter ();
*import = \ &Exporter::import;

@EXPORT_OK = qw( isq isaq );

sub esc {
    my ( $val ) = @_;

    $val =~ s/\n/\\n/g;
    $val =~ s/\e/\\e/g;
    $val =~ s/\t/\\t/g;

    return $val;
}

sub isq ($$;$) {
    my $got      = esc( $_[0] );
    my $expected = esc( $_[1] );
    my $name     = $_[2];

    Test::More::is( $got, $expected, $name );
}

sub isaq ($$;$) {

    my $got;
    if ( 'ARRAY' eq ref $_[0] ) {
        $got = [
            map { esc( $_ ) }
            @{$_[0]}
        ];
    }
    else {
        $got = $_[0];
    }

    my $expected = [
        map { esc( $_ ) }
        @{$_[1]}
    ];

    Test::More::is_deeply( $got, $expected, $_[2] );
}

1;
