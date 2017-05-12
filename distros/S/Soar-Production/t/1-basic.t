#test creation of productions and 


use strict;
use warnings;
use Test::More tests => 3;
use FindBin('$Bin');
use File::Spec;

use Soar::Production qw(prods_from_file);;

my $prod = Soar::Production->new(<<ENDPROD);
	sp{myName
		(state <s>)
		-->
		(<s> ^foo bar)
	}
ENDPROD

isa_ok($prod, 'Soar::Production', 'created new production');

is($prod->name, 'myName', 'name');

my $file = File::Spec->catfile($Bin,'testmulti.soar');

my $prods =  prods_from_file($file);

my @names = map { $_->name } @$prods;

my $expected = [qw(propose*add apply*add remove*complete*commands)];
is_deeply (\@names, $expected, 'correctly created productions from file');
