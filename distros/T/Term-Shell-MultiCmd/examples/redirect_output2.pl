
use lib 'lib', '../lib' ;
use Term::Shell::MultiCmd;

my $ret_value ;
my $cli = new Term::Shell::MultiCmd ( -pager => sub {
                                          open my $fh, '>', \$ret_value or die "can't open FileHandle to string (no PerlIO?)\n" ;
                                          $fh
                                      },
                                      -pager_re => '',
                                    ) ;
# ...
$cli -> cmd ('help -t') ;

print "ret_value is:\n $ret_value" ;
