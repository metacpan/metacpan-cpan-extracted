package Pfacter::ipaddress;

#

sub pfact {
    my $self  = shift;
    my ( $p ) = shift->{'pfact'};

    my ( $r );

    for ( $p->{'kernel'} ) {
        /AIX|Darwin|FreeBSD|SunOS/ && do {
            my ( $c );

            $c = '/etc/ifconfig -a |'  if -e '/etc/ifconfig';
            $c = '/sbin/ifconfig -a |' if -e '/sbin/ifconfig';

            if ( $c ) {
                open( F, $c );
                my ( @F ) = <F>;
                close( F );

                my ( $d, @i );

                foreach ( @F ) {
                    $d = $1 if /^(\w+)\:/;
                    push @i, "$d=$1" if /inet\s+(\d+\.\d+\.\d+\.\d+)/;
                };

                $r = join ' ', sort @i;
            }
        };

        /Linux/ && do {
            if ( -e '/sbin/ifconfig' ) {
                open( F, '/sbin/ifconfig -a |' );
                my ( @F ) = <F>;
                close( F );

                my ( $d, @i );

                foreach ( @F ) {
                    $d = $1 if ( /^(\w+)\s+/ || /^(\w+:\d+)\s+/ );
                    push @i, "$d=$1" if /inet addr:(\d+\.\d+\.\d+\.\d+)/;
                }

                $r = join ' ', sort @i;
            }
        };

        if ( $r ) { return( $r ); }
        else      { return( 0 ); }
    }
}

1;
