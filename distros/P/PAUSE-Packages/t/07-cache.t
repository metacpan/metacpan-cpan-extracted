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

    ok( $pp->from_cache, 'URL is cached locally' );
}

{
    my $file = file( 't', '02packages.details.txt' );

    my $pp = PAUSE::Packages->new(
	path => "$file",
    );

    ok( ! $pp->from_cache, 'Path is not cached locally' );
}

done_testing();
