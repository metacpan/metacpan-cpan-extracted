#!perl

use strict;
use warnings;

use Test::More 0.88;
use Test::Fatal;

use LWP::UserAgent;
use PAUSE::Packages;
use Path::Class qw( file );
use URI::FromHash qw( uri );

#-----------------------------------------------------------------------
# construct PAUSE::Packages
#-----------------------------------------------------------------------

{
    my $file = file( 't', '02packages.details.txt' );
    my $url = uri(
        path   => $file->absolute->stringify,
        scheme => 'file',
    );

    my $pp = PAUSE::Packages->new(
        ua  => LWP::UserAgent->new(),
        url => $url,
    );

    ok( $pp->release( 'Acme-Urinal' ), 'has Acme-Urinal release.' );
}

{
    my $file = file( 'foo', '02packages.details.txt' );
    my $url = uri(
        path   => $file->absolute->stringify,
        scheme => 'file',
    );

    like(
        exception(
            sub {
                my $pp = PAUSE::Packages->new(
                    ua  => LWP::UserAgent->new(),
                    url => $url,
                );
            }
        ),
        qr{404},
        'dies when file not found'
    );
}
done_testing();
