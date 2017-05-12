use lib 'lib';
use lib '../lib';
use 5.006;
use strict;
use warnings;
use Test::More tests => 33;
use Perlmazing;

my $cases = {
	'!def!xyz%abc@example.com'										=> 1,
	'"Abc@def"@example.com'											=> 1,
	'"Abc\"def"@example.com'										=> 1,
	'"Abc\@def"@example.com'										=> 1,
	'"Fred Bloggs"@example.com'										=> 1,
	'"Joe\\Blow"@example.com'										=> 1,
	'-dashy@example.net'											=> 1,
	'0@example.com'													=> 1,
	'1@example.com'													=> 1,
	'123@example.com'												=> 1,
	'$A12345@example.com'											=> 1,
	'Alfred Neuman <Neuman@BBN-TENEXA>'								=> 0,
	'Fred\"Bloggs@example.com'										=> 0,
	'_somename@example.com'											=> 1,
	('a' x 64).'@example.com'										=> 1,
	('a' x 65).'@example.com'										=> 0,
	'customer/department=shipping@example.com'						=> 1,
	'dashy@-example.net'											=> 0,
	'dashy@a--o.example.net'										=> 1,
	'dashy@a.a.example.net'											=> 1,
	'dashy@ao.example.net'											=> 1,
	'dashy@example.net-'											=> 0,
	'first last@aol.com'											=> 0,
	'foo @ foo.com'													=> 1,
	'foo@foo.com'													=> 1,
	'fred&barney@stonehenge(yup, the rock place).(that\'s dot)com}'	=> 0,
	'fred&barney@stonehenge.com'									=> 1,
	'rjbs@[127.0.0.1]'												=> 1,
	'somebody@ example.com'											=> 1,
	'somebody@example.com'											=> 1,
	'user+name@gmail.com'											=> 1,
	'user@example.'.('a' x (254 - 13))								=> 1,
	'user@example.'.('a' x (255 - 13))								=> 0,
};

for my $i (sort numeric keys %$cases) {
	my $r = is_email_address($i) ? 1 : 0;
	is $r, $cases->{$i}, $i;
}
