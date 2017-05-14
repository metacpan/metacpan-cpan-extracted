package Pfacter::kernelversion;

#

sub pfact {
    my $self  = shift;
    my ( $p ) = shift->{'pfact'};

    my ( $r );

    for ( $p->{'kernel'} ) {
        /AIX|Darwin|FreeBSD|Linux|SunOS/ && do {
            if ( -e '/bin/uname' )     { $r = qx( /bin/uname -v ); }
            if ( -e '/usr/bin/uname' ) { $r = qx( /usr/bin/uname -v ); }
        };

        if ( $r ) { return( $r ); }
        else      { return( 0 ); }
    }
}

1;
