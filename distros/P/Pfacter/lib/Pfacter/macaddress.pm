package Pfacter::macaddress;

#

sub pfact {
    my $self  = shift;
    my ( $p ) = shift->{'pfact'};

    my ( $r );

    for ( $p->{'kernel'} ) {
        /AIX/ && do {
            my ( $d, @i );

            if ( -e '/usr/bin/netstat' ) {
                open( F, '/usr/bin/netstat -ia |' );
                my ( @F ) = <F>;
                close( F );

                foreach ( @F ) {
                    $d = $1 if /^(\w+)\s+/;
                    push @i, "$d=$1" if /(\w+\:\w+\:\w+\:\w+\:\w+\:\w+)/;
                }

                $r = join ' ', sort @i;
            }
        };

        /Darwin|FreeBSD|Linux|SunOS/ && do {
            my ( $d, @i );

            if ( -e '/sbin/ifconfig' ) {
                open( F, '/sbin/ifconfig -a |' );
                my ( @F ) = <F>;
                close( F );

                foreach ( @F ) {
                    $p->{'kernel'} =~ /Darwin|FreeBSD|SunOS/ && do {
                        $d = $1 if /^(\w+)\:/;
                        push @i, "$d=$1"
                            if /ether\s+(\w+\:\w+\:\w+\:\w+\:\w+\:\w+)/;
                    };

                    $p->{'kernel'} =~ /Linux/ && do {
                        $d = $1 if ( /^(\w+)\s+/ || /^(\w+:\d+)\s+/ );
                        push @i, "$d=$1"
                            if /HWaddr\s+(\w+\:\w+\:\w+\:\w+\:\w+\:\w+)/;
                    };
                }

                $r = join ' ', sort @i;
            }
        };

        if ( $r ) { return( $r ); }
        else      { return( 0 ); }
    }
}

1;
