use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Fatal;
use TestDBH;
use TestEnv;

use ObjectDB::Table;
use Person;

subtest 'update_objects' => sub {
    _setup();

    Person->new(name => 'vti')->create;

    my $table = _build_table();
    $table->update(set => { name => 'foo' });

    my $person = Person->new(id => 1)->load;

    is($person->get_column('name'), 'foo');
};

subtest 'update_objects_with_query' => sub {
    _setup();

    Person->new(name => 'vti')->create;
    Person->new(name => 'foo')->create;

    my $table = _build_table();
    $table->update(set => { name => 'bar' }, where => [ name => 'foo' ]);

    my $person = Person->new(id => 1)->load;
    is($person->get_column('name'), 'vti');

    $person = Person->new(id => 2)->load;
    is($person->get_column('name'), 'bar');
};

subtest 'return_number_of_updated_rows' => sub {
    _setup();

    Person->new(name => 'vti')->create;
    Person->new(name => 'foo')->create;

    my $table = _build_table();
    is $table->update(set => { name => 'bar' }, where => [ name => 'foo' ]), 1;
};

done_testing;

sub _setup {
    TestEnv->prepare_table('person');
}

sub _build_table {
    ObjectDB::Table->new(class => 'Person', dbh => TestDBH->dbh, @_);
}
