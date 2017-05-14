package Pfacter::uniqueid;

#

sub pfact {
    my $self  = shift;
    my ( $p ) = shift->{'pfact'};

    my ( $r );

    for ( $p->{'kernel'} ) {
        /AIX/ && do {
            if ( -e '/usr/bin/uname' ) {
                $r = qx( /usr/bin/uname -f );
            }
        };

        /Linux|SunOS/ && do {
            if ( -e '/usr/bin/hostid' ) {
                $r = qx( /usr/bin/hostid );
            }
        };

        if ( $r ) { return( $r ); }
        else      { return( 0 ); }
    }
}

1;
