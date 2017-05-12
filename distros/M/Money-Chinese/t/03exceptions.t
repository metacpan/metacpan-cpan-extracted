#########################

use Test::More;

BEGIN {
	eval 'use Test::Exception';
	plan( skip_all => 'Test::Exception needed' )if $@;
}

plan( tests => 4);

#########################

use Money::Chinese;

throws_ok { &expecting_to_die('abc') } qr/An Arabic numeral with the format of/, '\'abc\' caught ok';
throws_ok { &expecting_to_die('***+++$$$') } qr/An Arabic numeral with the format of/, 'void symbol caught ok';
throws_ok { &expecting_to_die('0') } qr/A non zero Arabic numeral is expected/, '\'0\' caught ok';
throws_ok { &expecting_to_die('0.00') } qr/A non zero Arabic numeral is expected/, '\'0.00\' caught ok';
#dies_ok { &expecting_to_die('0') } 'expecting to die';

sub expecting_to_die {
	my $object = Money::Chinese->new;
	$object->convert($_[0]);
}
