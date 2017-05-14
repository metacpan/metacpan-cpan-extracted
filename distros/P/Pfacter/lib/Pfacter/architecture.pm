package Pfacter::architecture;

#

sub pfact {
    my $self  = shift;
    my ( $p ) = shift->{'pfact'};

    my ( $r );

    for ( $p->{'kernel'} ) {
        /AIX|Darwin|FreeBSD|Linux|SunOS/ && do {
            if ( -e '/bin/uname' )    { $r = qx( /bin/uname -p ); }
            if ( -e '/usr/bin/uname' ) { $r = qx( /usr/bin/uname -p ); }
        };

        if ( $r ) { return( $r ); }
        else      { return( 0 ); }
    }
}

1;
