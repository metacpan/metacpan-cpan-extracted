package Pfacter::kernel;

#

sub pfact {
    my ( $r );

    if ( -e '/bin/uname' )     { $r = qx( /bin/uname -s ); }
    if ( -e '/usr/bin/uname' ) { $r = qx( /usr/bin/uname -s ); }

    if ( $r ) { return( $r ); }
    else      { return( 0 ); }
}

1;
