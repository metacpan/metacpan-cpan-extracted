#
#===============================================================================
#         FILE:  bibliosim.t
#      CREATED:  07/05/2009 09:32:45 PM
#===============================================================================

use strict;
use warnings;

use Test::More;
use Data::Dumper;
use Scalar::Util qw(looks_like_number);

use lib qw(t/lib lib ../lib);

require_ok('SQL::Bibliosoph::Sims');

sub std_tests {
    my $bs   = shift; 
    my $name = shift || ''; 

    isa_ok($bs,"SQL::Bibliosoph::Sims");

    is(ref($bs->USER()),"ARRAY", "QUERY() is an array" );
    is(ref($bs->USER()->[0]),"ARRAY", "QUERY()->[0] is an array");
    is(ref($bs->USER()->[0]->[0]),"", "QUERY()->[0]->[0] is a scalar");

    is(ref($bs->h_USER()),"ARRAY", "h_QUERY() is an array");

    is(ref($bs->h_USER()->[0]),"HASH", "h_QUERY()->[0] is a hash");

    is(ref($bs->rowh_USER()),"HASH", "rowh_QUERY() is a hash");


    my $a =  $bs->USER()->[0]->[0];
    ok(looks_like_number $a, "QUERY()->[0]->[0] is a number");

    $a =  $bs->USER()->[4]->[4234];
    ok(looks_like_number $a, "QUERY()->[8]->[4234] is a number");


};

my $bs = new SQL::Bibliosoph::Sims();
std_tests($bs);

my ($l,$b) =  $bs->h_USER();
ok($b == 10, "Size is 10");
ok(ref($l) eq "ARRAY", "h_QUERY() is an array with 10 rows");


# ------------------------------------------------------------------------
note "Now testing a 5 rows resultset...";
$bs = new SQL::Bibliosoph::Sims(rows=>5);
std_tests($bs);

($l,$b) =  $bs->h_USER();
ok($b == 5, "Size is 5 vs $b");
ok(ref($l) eq "ARRAY", "h_QUERY() is an array with 5 rows");

# ------------------------------------------------------------------------
note "Now testing a presets...";
# Presets
my $h1_code = '{ a=>1, b=>2 }';
my $h1 = eval $h1_code; 

$bs = new SQL::Bibliosoph::Sims( 
            presets => { 
                    TITo => $h1_code,
                    rowh_RANDy=> ' {name => join "", rand_chars( set=> "alpha", min=>5, max=>7) } ',
                    rowh_RAND2y=> ' {name => join "", rand_chars( set=> "numeric", min=>5, max=>7) } ',
                    row_RAND3y=> ' [ 0, join "",rand_chars( set=> "numeric", min=>5, max=>7)] ',
            }, 
      );
($l,$b) =  $bs->TITo();
ok(eq_hash($l, $h1) , 'presets support: TITo');


my $h =  $bs->rowh_RANDy();
ok( $h->{name} =~ /^[A-Za-z]+$/ , 'name is a random string : ' . $h->{name});

$h =  $bs->rowh_RAND2y();
ok( $h->{name} =~ /^[0-9]+$/ , 'name is a random number : ' . $h->{name});

$h =  $bs->row_RAND3y();
ok( $h->[1] =~ /^[0-9]+$/ , 'name is a random number : ' . $h->[1]);

# ------------------------------------------------------------------------
note "Now testing a presets catalogs...";

my $file = 'etc/tests.bb';
$bs = undef;

SKIP: {
    skip "Could not find $file", 3  unless -e $file;


    $bs = new SQL::Bibliosoph::Sims( presets_catalog =>  $file );
    ($l,$b) =  $bs->TITo();
    ok(eq_hash($l, $h1) , 'presets support: TITo');


    my $h =  $bs->rowh_RANDy();
    ok( $h->{name} =~ /^[A-Za-z]+$/ , 'name is a random string : ' . $h->{name});

    $h =  $bs->rowh_RAND2y();
    ok( $h->{name} =~ /^[0-9]+$/ , 'name is a random number : ' . $h->{name});

  
    my $a = $bs->h_RAND3(1,2);

    is( ref($a) , 'ARRAY' , ' $a is an array');
    is( ref($a->[0]) , 'HASH' , ' $a->[0] is a hash');
    is( $a->[0]->{role_code} , 1 , '$a->[0]->{role_code} is 1'); 

    eval {
        $bs->BAD();
    };
    if ($@ =~ /syntax/) {
        pass ("Catalog with bad syntax should die");
    }
    else {
        fail ("Catalog with bad syntax should die");
    }
};




done_testing();


