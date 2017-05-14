package Pfacter::hardwareplatform;

#

sub pfact {
    my $self  = shift;
    my ( $p ) = shift->{'pfact'};

    my ( $r );

    for ( $p->{'kernel'} ) {
        /AIX/ && do {
            if ( -e '/usr/sbin/lsattr' ) {
                open( F, '/usr/sbin/lsattr -El proc0 |' );
                my ( @F ) = <F>;
                close( F );

                foreach ( @F ) {
                    if ( /type\s+.*_(\w+)\s/ ) { $r = $1; last; }
                }
            }
        };

        /Darwin/ && do {
            if ( -e '/usr/bin/machine') { $r = qx( /usr/bin/machine ); }
        };

        /Linux/ && do {
            if ( -e '/bin/uname' ) { $r = qx( /bin/uname -i ); }
        };

        /SunOS/ && do {
            if ( -e '/usr/bin/uname' ) {
                $r = qx( /bin/uname -i );
                $r = $1 if /^(.+?),.*$/;
            }
        };

        if ( $r ) { return( $r ); }
        else      { return( 0 ); }
    }
}

1;
