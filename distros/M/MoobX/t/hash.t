use Test::More;

use 5.20.0;

use experimental 'signatures';

use MoobX;

observable my %hash;

my @checks = ( sub (%hash) { is_deeply \%hash, {} } );

my $o = autorun {
    my $check = shift @checks;
    $check->(%hash) or diag explain \%hash;
};

push @checks, sub (%hash) { is_deeply \%hash, { foo =>  'bar' }, 'update a value' };
$hash{foo} = 'bar';

push @checks, sub (%hash) { is_deeply \%hash, { foo =>  'bar', baz => [ 1..3 ] }, 'value as array' };
$hash{baz} = [ 1,2,3];

push @checks, sub (%hash) { is_deeply \%hash, { baz => [ 1..3 ] }, 'delete a key' };
delete $hash{foo};

push @checks, sub (%hash) { is_deeply \%hash, { baz => [ 1,4,3 ] }, 'array is updated' };
$hash{baz}[1] = 4;

done_testing;
