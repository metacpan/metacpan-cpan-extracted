package Pfacter::domain;

#

sub pfact {
    my $self  = shift;
    my ( $p ) = shift->{'pfact'};

    # Check for FQDN hostname first
    if ( -e '/bin/hostname' ) {
        return( $1 ) if qx( /bin/hostname ) =~ /\w+\.(.+?\.[a-z]{3})$/;
    }

    my ( $r );

    for ( $p->{'kernel'} ) {
        /Linux/ && do {
            if ( -e '/bin/dnsdomainname' ) {
                open( F, '/bin/dnsdomainname |' );
                my ( @F ) = <F>;
                close( F );

                foreach ( @F ) {
                    if ( /^(.*\.[a-z]{3})$/ ) { $r = $1; last; }
                }
            }
        };

        /AIX|Linux/ && do {
            if ( -e '/etc/resolv.conf' ) {
                open( F, '/etc/resolv.conf' );
                my ( @F ) = <F>;
                close( F );

                foreach ( @F ) {
                    if ( /domain\s+(.*\.[a-z]{3})/ ) { $r = $1; last; }
                }
            }
        };

        /SunOS/ && do {
            if ( -e '/bin/domainname' ) {
                $r = qx( /bin/domainname );
                undef( $r ) unless $r =~ /.*\.[a-z]{3}/;
            }
        };

        if ( $r ) { return( $r ); }
        else      { return( 0 ); }
    }
}

1;
