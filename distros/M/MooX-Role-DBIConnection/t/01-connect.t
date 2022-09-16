#!perl

use strict;
use Test::More tests => 3;

{
package My::Package;
    use Moo;
    with 'MooX::Role::DBIConnection';
}

my $t = My::Package->new(
    dbh => {
        dsn => 'dbi:Sponge:',
    },
);

ok !defined $t->{_dbh}, 'No dbh was created yet';
my $dbh = $t->dbh;
ok defined $t->{_dbh}, 'dbh was lazily created';

$t = My::Package->new(
    dbh => {
        dsn => 'dbi:Sponge:',
        eager => 1,
    },
);
ok defined $t->{_dbh}, 'dbh was created immediately';
