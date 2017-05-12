# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl POSIX-bsearch.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 14 };
use POSIX::bsearch;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.


my @unsorted = qw/ aboideau aboiteau adoulie aeluroid aequorin aerobium
agouties ajourise aleikoum anemious aquotize aureolin autocide autoecic
autosite auximone Beaudoin Beauvoir berairou Boileau boisseau bouteria
cadiueio caesious camoudie Caquetio Codiaeum Copiague dialogue douanier
douzaine edacious equation eulogia eulogiae eulogias euphonia euphoria
eutocia eutopia exonumia Figueroa Gerousia gerousia Gourinae iso-urea
jalousie Juloidea Laguiole miaoued moineau outimage outraise poulaine
quaestio Reboulia Roumelia sautoire Sequoia sequoia sequoias Souvaine
Teutonia thiourea Touraine vialogue /;
sub CF { ( $a =~ tr/A-Ztls// ) <=> ( $b =~ tr/A-Ztls// ) or $b cmp $a }
my @sorted = sort CF @unsorted;
# warn "@sorted";

# first, degenerate cases.

my @shouldbeempty = bsearch { 0 } mimsy => @{[]};
ok( 23+@shouldbeempty, 23, "search on empty array returns empty array" );

# try to find something that isn't there
   @shouldbeempty =  bsearch \&CF, mimsy => @sorted;
ok( 23+@shouldbeempty, 23, "search for absent member returns empty array" );


# find "equation"
my ($equation) = bsearch \&CF, equation => @sorted;
ok($equation => equation => 'find a unique key in array context');
ok($POSIX::bsearch::count, 1, 'unique means count == 1');
my $equat = bsearch \&CF, equation => @sorted;
ok($equat => equation => 'find a unique key in scalar context');
# find words with 5 vowels not e
my @Twoers = bsearch {
   # # warn "comparing $a to $b";
   ( $a =~ tr/A-Ztls// ) <=> ( $b =~ tr/A-Ztls// )
 } flat => @sorted;
# warn "the $POSIX::bsearch::count Twoers [@Twoers] start at $POSIX::bsearch::index";
ok("@Twoers","sequoias sautoire quaestio outraise jalousie eulogias caesious boisseau agouties Teutonia Roumelia Reboulia Laguiole Juloidea Gerousia Caquetio Boileau" );
ok($POSIX::bsearch::count, 17, 'Seventeen of them');
ok($POSIX::bsearch::index, 48, 'Starting at index 48');

# we should die on bad input

my $Betterbefalse = eval { @Twoers = bsearch {
   # # warn "comparing $a to $b";
   ( $a =~ tr/tls// ) <=> ( $b =~ tr/tls// )
 } l => @sorted; 1; };
 # # warn "got exception $@";
ok(!$Betterbefalse);

# KEY TOO LOW
my @MiddleLetters = qw/ J K L M N O P /;
@Twoers = bsearch { $a cmp $b } G => @MiddleLetters;
ok($#twoers, -1, "key too low returns empty list");
ok($POSIX::bsearch::index, -1, 'key too low sets index to -1');

# KEY TOO HIGH
@Twoers = bsearch { $a cmp $b } T => @MiddleLetters;
ok($#twoers, -1, "key too high returns empty list");
ok($POSIX::bsearch::index, 7, 'key too high sets index to array length');

1;

