package utils;

use Path::Class::File;

###
# the lighttpd management is taken from FCGI::Engine
###
    
sub find_lighttpd {
    my $lighttpd = map { chomp; $_ } `which lighttpd`;
    
    if ( ! -x "$lighttpd" ) {
    PREFIX:
        for my $prefix (qw(/usr /usr/local /opt/local /sw)) {
            for my $bindir (qw(bin sbin)) {
                $lighttpd="$prefix/$bindir/lighttpd";
                last PREFIX if -x "$lighttpd"
            }
        }
    }   
        
    return unless -x $lighttpd;
    return $lighttpd;
}   
     
sub lighttpd_pidfile {
    Path::Class::File->new('/tmp/lighttpd.pid')
}
        
sub start_lighttpd {
    my $conf = shift;
    system(find_lighttpd(), '-f', $conf);
}

sub stop_lighttpd {
    my $signal = shift || 'TERM';
    kill $signal => ((lighttpd_pidfile)->slurp(chomp => 1));
}

1;
