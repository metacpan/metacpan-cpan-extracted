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
ok( my $o = Mir::FileHandler->new( path => './t' ), 'new');

state $found={};
my $code = sub { 
    if ( $found->{ $_[0] } ) {
        return 0;
    } else { 
        $found->{ $_[0] } = 1;
        return 1;
    }
};

    # walk a directory and exec code for each file...
    # stops after max success code execution
    # the sub pointed by $code has to return 1 in
    # case of success
ok( $o->clear_cache(), 'clear_cache' );
ok( my $count = $o->dir_walk_max( 
    code => $code, 
    max  => 1 
), 'dir_walk for max 1 files...' );
is( $count, 1, 'Got right number of valid files' );

    # walk a directory and exec code for each file...
    # stops after max success code execution
    # the sub pointed by $code has to return 1 in
    # case of success
ok( $o->clear_cache(), 'clear_cache' );
$found={};
# this should restart from root
ok( $count = $o->dir_walk_max( 
    code => $code,
    max  => 1,
), 'dir_walk for max 1 files, restarting from root');
is( $count, 1, 'Got right number of valid files' );
# this should start from cache...
ok( $count = $o->dir_walk_max( 
    code => $code,
    max  => 50,
), 'dir_walk for max 50 files' );
diag "Count: $count";

done_testing();
