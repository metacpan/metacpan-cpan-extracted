use Test::More 'no_plan';


use Storm::Source;
my $source = Storm::Source->new;
ok $source, 'source instantiated';

$source->set_parameters( 'DBI:SQLite:dbname=:memory:' );
ok $source->dbh, 'created database handle';

