# This -*- perl -*- code tests the crypt stuff for completeness sake

# $Id: crypt.t,v 1.1 2002/12/18 08:45:13 lem Exp $

BEGIN {
    our @texts = ('All your base are belong to us',
		  'funny',
		  'abcba',
		  'abccba',
		  'abcdcba',
		  '1',
		  '0',
		  'This is a very very very long string that might be crypted',
		  );
};

use Test::More tests => 2 + 2 * @texts;
use SMS::Handler::Email;
use Queue::Dir;

END {
    rmdir "test$$";
};

mkdir "test$$";

my $q = new Queue::Dir
    (
     -paths => [ "test$$" ],
     -promiscuous => 1,
     );

my %State = ();

my $h = new SMS::Handler::Email (
				 queue => $q,
				 state => \%State,
				 secret => 'All your base are belong to us',
				 addr => '6.6.6',
				 pop => 'pop.foo.com',
				 smtp => 'smtp.foo.com',
				 );

isa_ok($h, 'SMS::Handler::Email');

is($h->_crypt(''), '', '_crypt of empty string is empty');

for my $t (@texts)
{
    my $c = $h->_crypt($t);
    my $T = $h->_crypt($c);
    is($T, $t, "_crypt of $t is reversible");
    isnt($c, $t, "_crypt of $t seems different");
}




