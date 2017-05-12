use Test::More;
use strict;
use warnings;
use Net::Proxy;

my @messages = (
    'ham tomato shrubbery pate herring truffle lobster aubergine',
    'kn na vn pk cy hn yu cc',
    'thwack kayo zlonk qunckkk zlott cr_r_a_a_ck clunk_eth bang',
    'The_Witch_of_Kaan Pipil_Khan Minstrel Sage Captain_Ahax Groo Chakaal',
    'barry wendel_j_stone_iv myron laura ed richard millard_bullrush dilbert',
    'lbrocard hvds ni_s gbarr lwall cbail mschwern rgarcia',
    'XPT MUR CNY MDL GHC MWK YER LTL',
    'elk wapiti antler alces_alces oryx moose caribou eland',
    'Jimmy_Carter Ronald_Reagan Chester_Arthur George_Washington Gerald_Ford',
    'Woodstock Rerun Peppermint_Patty Schroeder Pigpen Lucy Snoopy Linus',
    'manganese eckstine lowenstein gebrail gland maijstral girgis godolphin',
    'corge quux foobar fred waldo garply fubar grault',
    'strontium platine germanium rhodium hafnium californium chrome terbium',
    'maxime laboris adipisicing ullamco harum nobis sed inventore',
    'Braga Pittsburgh Saint_Louis Merlbourne Ottawa Belfast Chicago Paris',
    'mardi jeudi mercredi dimanche vendredi samedi lundi jeudi',
    'Gregory_Gaillard Delphine_Moussin Michael_Denard Geraldine_Wiart',
    'MONGOLIAN_LETTER_LA COMBINING_LATIN_SMALL_LETTER_X MYANMAR_SIGN_ANUSVARA',
    'ansys_lm kis netinfo_local pcia_rxp_b xpl hri_port nkd stmf',
    'holy_greed holy_ghost_writer holy_jawbreaker holy_barracuda',
    'Rea Sushi Stretch Garfield Clive Caped_Avenger Squeak Arlene',
    'spam toast ham lobster beans tomato aubergine',
    'period bullet underscore pilcrow ellipsis dagger permille_sign',
    'plugh foo quux foobar qux corge xyzzy',
    'MBOX SIZE QUIT XFER OK NMBR RETR',
    'Rerun Pigpen Charlie_Brown Schroeder Snoopy Marcie Linus',
    'orca classroom versatile repay inception narrative chatter',
    'Altair Electra Ancha Naos Canopus Merope Sadr',
    'greed anger envy laziness gluttony pride lust',
);
my @expected = @messages[ 0, 4, 8, 9, 12, 13, 14, 16, 17, 20 .. 24 ];

my $err = 'stderr.out';

plan tests => my $tests = @expected;

SKIP: {

    # logs are sent to STDERR
    # (this is not a very nice way to spit logging info)
    # so, dup STDERR and save it to stderr.out
    open OLDERR, ">&STDERR" or skip "Can't dup STDERR: $!", $tests;
    open STDERR, '>', $err or skip "Can't redirect STDERR: $!", $tests;
    select STDERR;
    $| = 1;    # make unbuffered

    # run our tests now
    my $i = 0;
    Net::Proxy->error( $messages[ $i++ ] );
    Net::Proxy->notice( $messages[ $i++ ] );
    Net::Proxy->info( $messages[ $i++ ] );
    Net::Proxy->debug( $messages[ $i++ ] );
    Net::Proxy->set_verbosity(0);
    Net::Proxy->error( $messages[ $i++ ] );
    Net::Proxy->notice( $messages[ $i++ ] );
    Net::Proxy->info( $messages[ $i++ ] );
    Net::Proxy->debug( $messages[ $i++ ] );
    Net::Proxy->set_verbosity(1);
    Net::Proxy->error( $messages[ $i++ ] );
    Net::Proxy->notice( $messages[ $i++ ] );
    Net::Proxy->info( $messages[ $i++ ] );
    Net::Proxy->debug( $messages[ $i++ ] );
    Net::Proxy->set_verbosity(2);
    Net::Proxy->error( $messages[ $i++ ] );
    Net::Proxy->notice( $messages[ $i++ ] );
    Net::Proxy->info( $messages[ $i++ ] );
    Net::Proxy->debug( $messages[ $i++ ] );
    Net::Proxy->set_verbosity(1);
    Net::Proxy->error( $messages[ $i++ ] );
    Net::Proxy->notice( $messages[ $i++ ] );
    Net::Proxy->info( $messages[ $i++ ] );
    Net::Proxy->debug( $messages[ $i++ ] );
    Net::Proxy->set_verbosity(3);
    Net::Proxy->error( $messages[ $i++ ] );
    Net::Proxy->notice( $messages[ $i++ ] );
    Net::Proxy->info( $messages[ $i++ ] );
    Net::Proxy->debug( $messages[ $i++ ] );
    Net::Proxy->set_verbosity(0);
    Net::Proxy->error( $messages[ $i++ ] );
    Net::Proxy->notice( $messages[ $i++ ] );
    Net::Proxy->info( $messages[ $i++ ] );
    Net::Proxy->debug( $messages[ $i++ ] );

    # get the old STDERR back
    open STDERR, ">&OLDERR" or die "Can't dup OLDERR: $!";
    close OLDERR;

    # read stderr.out
    open my $fh, $err or skip "Unable to open $err: $!";
    
    $i = 0;
    while (<$fh>) {
        like(
            $_,
            qr/\A\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d $expected[$i]\n\z/,
            "Expected line $i"
        );
        $i++;
    }
    
    # close and remove all files
    close $fh   or diag "close: $!";
    unlink $err or diag "unlink: $!";
}

