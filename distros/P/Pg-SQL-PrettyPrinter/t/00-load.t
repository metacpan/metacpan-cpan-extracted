#!perl

use Test::More;
use FindBin;
use File::Basename;

BEGIN {
    my $manifest = dirname( $FindBin::Bin ) . '/MANIFEST';
    open( my $fh, '<', $manifest ) or die "Can't open $manifest: $!";
    my @libs = grep { m#\Alib/.*\.pm\s*\z# } <$fh>;
    close $fh;
    plan tests => scalar @libs;
    for my $pm ( @libs ) {
        $pm =~ s{^lib/}{};
        $pm =~ s/\.pm\s*\z//;
        $pm =~ s{/}{::}g;
        use_ok( $pm );
    }
}
