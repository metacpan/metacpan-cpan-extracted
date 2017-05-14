package Pfacter::operatingsystem;

#

sub pfact {
    my $self  = shift;
    my ( $p ) = shift->{'pfact'};

    my ( $r );

    for ( $p->{'kernel'} ) {
        /AIX/ && do {
            $r = 'AIX';
        };

        /Darwin/ && do {
            $r = 'OSX';
        };

        /FreeBSD/ && do {
            $r = 'FreeBSD';
        };

        /Linux/ && do {
            if ( -e '/etc/debian_version' ) { $r = 'Debian'; }
            if ( -e '/etc/gentoo-release' ) { $r = 'Gentoo'; }
            if ( -e '/etc/fedora-release' ) { $r = 'Fedora'; }
            if ( -e '/etc/redhat-release' ) { $r = 'RedHat'; }
            if ( -e '/etc/SuSE-release' )   { $r = 'SuSE'; }
        };

        /SunOS/ && do {
            $r = 'Solaris';
        };

        if ( $r ) { return( $r ); }
        else      { return( 0 ); }
    }
}

1;
