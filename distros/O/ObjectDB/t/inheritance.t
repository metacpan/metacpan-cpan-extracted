use strict;
use warnings;
use lib 't/lib';

use Test::More;
use TestEnv;

use Person;
use Parent;

subtest 'inherits meta adding columns' => sub {
    _setup();

    my $person = Person->new(name => 'vti', age => 123)->create;
    $person->load;
    is $person->get_column('age'), undef;

    my $parent = Parent->new(name => 'vti', age => 123)->create;
    $parent->load;
    is $parent->get_column('age'), 123;
};

subtest 'inherits meta adding relationships' => sub {
    _setup();

    my $parent = Parent->new(name => 'vti', age => 123)->create;
    $parent->create_related('books', title => 'Hello');

    is $parent->related('books')->[0]->get_column('title'), 'Hello';
};

done_testing;

sub _setup {
    TestEnv->prepare_table('person');
    TestEnv->prepare_table('book');
}
