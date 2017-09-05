use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Fatal;
use TestDBH;
use TestEnv;

use ObjectDB::Table;
use Person;

subtest 'delete_objects ' => sub {
    _setup();

    Person->new(name => ' vti ')->create;

    my $table = _build_table();
    $table->delete;

    is($table->count, 0);
};

subtest 'delete_objects_with_query' => sub {
    _setup();

    Person->new(name => 'vti')->create;
    Person->new(name => 'foo')->create;

    my $table = _build_table();
    $table->delete(where => [ name => 'foo' ]);

    is($table->count, 1);
};

subtest 'return_number_of_deleted_rows' => sub {
    _setup();

    Person->new(name => 'vti')->create;
    Person->new(name => 'foo')->create;

    my $table = _build_table();
    is $table->delete, 2;
};

done_testing;

sub _setup {
    TestEnv->prepare_table('person');
}

sub _build_table {
    ObjectDB::Table->new(class => 'Person', dbh => TestDBH->dbh, @_);
}
