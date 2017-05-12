use Test::Spec;

use lib 't/lib';

use TestEnv;

use Person;
use Parent;

describe 'inheritance' => sub {
    before each => sub {
        TestEnv->prepare_table('person');
        TestEnv->prepare_table('book');
    };

    it 'inherits meta adding columns' => sub {
        my $person = Person->new(name => 'vti', age => 123)->create;
        $person->load;
        is $person->get_column('age'), undef;

        my $parent = Parent->new(name => 'vti', age => 123)->create;
        $parent->load;
        is $parent->get_column('age'), 123;
    };

    it 'inherits meta adding relationships' => sub {
        my $parent = Parent->new(name => 'vti', age => 123)->create;
        $parent->create_related('books', title => 'Hello');

        is $parent->related('books')->[0]->get_column('title'), 'Hello';
    };

};

sub _build_object {
    Table->new(@_);
}

runtests unless caller;
