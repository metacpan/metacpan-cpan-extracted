use strict;
use Test::More;
use SVN::Dump::Reader;

# the many way to fail
my %test = (
    false     => '',
    string    => 'file',
    reference => \'file',
    object    => bless( {}, 'Zlonk'),
);

plan tests => scalar keys %test;

for my $t ( keys %test ) {
    eval { my $r = SVN::Dump::Reader->new( $test{$t} ); };
    like( $@, qr/^SVN::Dump::Reader parameter is not a filehandle/, $t );

}

