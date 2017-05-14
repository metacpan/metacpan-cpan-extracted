package Pfacter::productid;

#

sub pfact {
    my $self  = shift;
    my ( $p ) = shift->{'pfact'};

    my ( $r );

    for ( $p->{'kernel'} ) {
        /Linux/ && do {
            if ( -e '/usr/sbin/dmidecode' ) {
                open( F, '/usr/sbin/dmidecode 2>/dev/null |' );
                my ( @F ) = <F>;
                close( F );

                foreach ( @F ) {
                    if ( /Product ID\:\s+(.+?)$/ ) { $r = $1; last; }
                }

                $r =~ s/\s+$//;
            }
        };

        if ( $r ) { return( $r ); }
        else      { return( 0 ); }
    }
}

1;
