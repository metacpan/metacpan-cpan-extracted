use strict;
use warnings;
use feature 'state';
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($DEBUG);

use Test::More;

BEGIN { 
    use_ok('Mir::FileHandler');
}

    # get a new FileHandler obj for the passed root directory
ok( my $o = Mir::FileHandler->new( path => './lib' ), 'new');

state $found={};
my $code = sub { 
    if ( $found->{ $_[0] } ) {
        diag "File $_[0] already present, skipping!\n";;
        return 0;
    } else { 
        diag "File $_[0] NEW !\n";;
        $found->{ $_[0] } = 1;
        return 1;
    }
};

ok( my $count = $o->dir_walk( code => $code ), 'dir_walk');
is( scalar keys %$found, $count, 'Got right number of files under ./lib which by the way are '.$count);

done_testing();
