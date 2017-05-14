package Pfacter::serialnumber;

#

sub pfact {
    my $self  = shift;
    my ( $p ) = shift->{'pfact'};

    my ( $r );

    for ( $p->{'kernel'} ) {
        /AIX/ && do {
            if ( -e '/usr/sbin/lsattr' ) {
                open( F, '/usr/sbin/lsattr -El sys0 -a systemid |' );
                my ( @F ) = <F>;
                close( F );

                foreach ( @F ) { if ( /,(.+?)\s+/ ) { $r = $1; last; } }

                $r =~ s/\s+$//;
            }
        };

        /Darwin/ && do {
            if ( -e '/usr/sbin/system_profiler' ) {
                open( F, '/usr/sbin/system_profiler SPHardwareDataType |' );
                my ( @F ) = <F>;
                close( F );

                foreach ( @F ) {
                    if ( /Serial Number\:\s+(.+?)$/ ) { $r = $1; last; }
                }
            }
        };

        /Linux/ && do {
            if ( -e '/usr/sbin/dmidecode' ) {
                open( F, '/usr/sbin/dmidecode 2>/dev/null |' );
                my ( @F ) = <F>;
                close( F );

                foreach ( @F ) {
                    if ( /Serial Number\:\s+(.+?)$/ ) { $r = $1; last; }
                }

                $r =~ s/\s+$//;
            }
        };

        if ( $r ) { return( $r ); }
        else      { return( 0 ); }
    }
}

1;
