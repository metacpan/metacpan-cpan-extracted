
use lib 'lib', '../lib' ;
use Term::Shell::MultiCmd;

sub create_my_own_given_filehandle() {
    print "creating a filehanle for pipe\n" ;
    my $fh ;
    return $fh if open $fh, '|-' ;
    # fork area
    while (my $line = <STDIN>) {
        print "pipe got: $line" ;
    }
    exit ;
}

my $given_filehandle ;
my $cli = new Term::Shell::MultiCmd ( -pager => sub { $given_filehandle ||= create_my_own_given_filehandle() },
                                      -pager_re => '',
                                    ) ;

for ('help', 'help -t' ) {
    print "sending command '$_' ..\n" ;
    $cli -> cmd ($_);
}


