package t::PreReq;

use strict;
use warnings;

sub load
{
    my( $skip, @packages ) = @_;

    my @missing;
    foreach my $package ( @packages ) {
        eval "use $package;";
        push @missing, $package if $@;
    }

    return unless @missing;
    SKIP: {
        my $m = join ', ', @missing;
        ::skip( "Need $m", $skip );
    }
    exit 0;
}

1;