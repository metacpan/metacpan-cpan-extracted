#!/usr/bin/perl

use lib 't/lib';

use Test::Mite;

tests "BUILDARGS" => sub {
    mite_load <<'CODE';
package CCC;
use Mite::Shim;
has list => is => 'ro';
sub BUILDARGS {
    my ( $self, @args ) = @_;
    return { list => \@args };
}
1;
CODE

    no warnings 'once';

    my $o = CCC->new( 1, 2, 3 );
    is_deeply(
        $o->list,
        [ 1, 2, 3 ],
        'expected results',
    );
};

done_testing;
