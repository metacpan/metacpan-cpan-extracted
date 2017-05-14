package Pfacter::wwn;

sub pfact {
    my $self  = shift;
    my ( $p ) = shift->{'pfact'};

    for ( $p->{'kernel'} ) {
        /AIX/ && do {
            my ( @h, @w );

            open( F, '/usr/sbin/lscfg |' );
            my ( @F ) = <F>;
            close( F );

            foreach ( @F ) { push @h, $1 if /^\+\s+(fc.+?)\s+/; }

            foreach my $d ( @h ) {
                open( F, "/usr/sbin/lscfg -vl $d |" );
                my ( @F ) = <F>;
                close( F );

                foreach ( @F ) {
                    push @w, "$d=$1" if /Network Address\.+(\w+)/;
                }
            }

            return join ' ', sort @w;
        };

        return qq((kernel not supported));
    }
}

1;
