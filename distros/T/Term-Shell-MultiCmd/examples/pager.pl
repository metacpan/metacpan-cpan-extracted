
use lib 'lib', '../lib' ;
use Term::Shell::MultiCmd;
my $pager = 'less -qrX' ;
my $cli = Term::Shell::MultiCmd->new(-pager => $pager );

$cli -> populate( 'config show' =>
                  { help => 'Show my \%Config',
                    exec => sub {
                        use Config ;
                        use Data::Dumper ;
                        print Dumper \%Config ;
                    }
                  },
                  'pager' =>
                  { help => 'set/show current pager' ,
                    exec => sub {
                        my ($o, %p) = @_ ;
                        $o->{pager} = $pager = "@{$p{ARGV}}" if @{$p{ARGV}} ;
                        print "pager is '$pager'\n" ;
                    }
                  }
                ) ;

print <<"Hi" ;
To view your perl configuration in pager, try the command '| config show'. To
change the pager, try something like: 'pager more'.

Hi

$cli -> loop ;

