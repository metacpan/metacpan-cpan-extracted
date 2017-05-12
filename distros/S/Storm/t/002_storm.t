use Test::More 'no_plan';


use Storm;
my $storm = Storm->new( source => ['DBI:SQLite:dbname=:memory:'] );
ok $storm, 'storm instantiated';
ok $storm->source, 'source object created';
ok $storm->source->dbh, 'database handle created';

