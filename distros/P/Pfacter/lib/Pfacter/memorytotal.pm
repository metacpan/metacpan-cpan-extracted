package Pfacter::memorytotal;

#

sub pfact {
    my $self  = shift;
    my ( $p ) = shift->{'pfact'};

    my ( $r );

    for ( $p->{'kernel'} ) {
        /AIX/ && do {
            if ( -e '/usr/sbin/lsattr' ) {
                open( F, '/usr/sbin/lsattr -El sys0 |' );
                my ( @F ) = <F>;
                close( F );

                foreach ( @F ) { if ( /realmem\s+(\d+)/ ) { $r = $1; last; } }
            }
        };

        /Darwin/ && do {
            if ( -e '/usr/bin/hostinfo' ) {
                open( F, '/usr/bin/hostinfo |' );
                my ( @F ) = <F>;
                close( F );

                foreach ( @F ) {
                    if ( /Primary\smemory\savailable:\s(.*)/ ) {
                        $r = $1;

                        $r =~ s/\smegabytes/m/g;
                        $r =~ s/\sgigabytes/g/g;

                        $r =~ s/\.00//g;
                    }
                }
            }
        };

        /FreeBSD/ && do {
            if ( -e '/sbin/dmesg' ) {
                open( F, '/sbin/dmesg |' );
                my ( @F ) = <F>;
                close ( F );

                foreach ( @F ) {
                    if ( /real memory.+?(\d+)K/ ) { $r = $1; last; }
                }
            }
        };

        /Linux/ && do {
            if ( -e '/proc/meminfo' ) {
                open( F, '/proc/meminfo' );
                my ( @F ) = <F>;
                close( F );
 
                foreach ( @F ) {
                    if ( /MemTotal:\s+(\d+)\s+\w+/ ) { $r = $1; last; }
                }
            }
        };

        /SunOS/ && do {
            if ( -e '/usr/sbin/prtconf' ) {
                open( F, '/usr/sbin/prtconf |' );
                my ( @F ) = <F>;
                close( F );

                foreach ( @F ) {
                    if ( /Memory size\:\s+(\d+)\s+(Megabytes)/ ) {
                        if ( $2 eq 'Megabytes' ) { $r = $1*1024; }
                    }
                }
            }
        };

        if ( $r ) { return( $r ); }
        else      { return( 0 ); }
    }
}

1;
