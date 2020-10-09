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

# get plain files list inside the root directory
ok( my $list = $o->plainfiles(), 'plainfiles' ); # or pass a path in input
note "Plainfiles under './lib' folder:";
note explain $list;

    # get plain files list from folder and sub-folders
    # gli passo la cartella radice, una lista di suffissi ed eventualmente un
    # handler per il processamento delle risorse
    # se non gli passo l'handler allora usa quello di default
ok( $list = $o->plainfiles_recursive(), 'plainfiles_recursive' );
note "Plainfiles under './lib' folder (and subfolders):";
note explain $list;

done_testing();
