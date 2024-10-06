#!perl
use strict;
use Test2::V0 '-no_srand';

{
package My::Package;
    use Moo;
    with 'MooX::Role::DBIConnection';
}

my $t = My::Package->new(
    dbh => {
        dsn => 'dbi:Sponge:',
        eager => 1,
    },
);

my $old_dbh =  $t->{_dbh};
ok defined $old_dbh, 'dbh was created';

$t->reconnect_dbh;
ok $old_dbh != $t->dbh, "We created a fresh dbh on reconnect";

done_testing();
