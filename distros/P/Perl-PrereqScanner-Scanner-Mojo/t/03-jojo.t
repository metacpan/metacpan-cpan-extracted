
use 5.010;
use Test::More 0.88;

use Perl::PrereqScanner;

my @TESTS = (
    {
        perl_code => <<'PERL',

package Cat {
  use Jojo::Base -base;    # requires perl 5.18+
 
  has name => 'Nyan';
  has ['age', 'weight'] => 4;
}
 
package Tiger {
  use Jojo::Base 'Cat';
 
  has friend => sub { Cat->new };
  has stripes => 42;
}
 
package main;
use Jojo::Base -strict;
 
my $mew = Cat->new(name => 'Longcat');
say $mew->age;
say $mew->age(3)->weight(5)->age;
 
my $rawr = Tiger->new(stripes => 38, weight => 250);
say $rawr->tap(sub { $_->friend->name('Tacgnol') })->weight;

PERL
        expected => { 'Cat' => '0', 'Jojo::Base' => '0' },
        what     => 'Jojo::Base synopsis',
    },
);

for my $t (@TESTS) {
    my $perl_code = $t->{perl_code};
    my $expected  = $t->{expected};
    my $name      = $t->{what} . " - right prereqs";

    my $scanner = Perl::PrereqScanner->new( { extra_scanners => ['Jojo'] } );
    my $prereqs = $scanner->scan_string($perl_code)->as_string_hash;
    is_deeply( $prereqs, $expected, $name );
}

done_testing;
