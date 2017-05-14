package Pfacter::lsbdescription;

#

sub pfact {
    my $self  = shift;
    my ( $p ) = shift->{'pfact'};

    my ( $r );

    for ( $p->{'kernel'} ) {
        /Linux/ && do {
            my ( $c );

            $c = '/bin/lsb_release -d |'     if -e '/bin/lsb_release';
            $c = '/usr/bin/lsb_release -d |' if -e '/usr/bin/lsb_release';

            if ( $c ) {
                open( F, $c );
                my ( @F ) = <F>;
                close( F );

                foreach ( @F ) { if ( /\:\s+(.*)$/ ) { $r = $1; last; } }
            }
        };

        if ( $r ) { return( $r ); }
        else      { return( 0 ); }
    }
}

1;
