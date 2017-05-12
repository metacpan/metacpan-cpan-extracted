use Test::Spec;
use Test::Fatal;

use lib 't/lib';

use TestDBH;
use TestEnv;
use Book;
use BookDescription;

describe 'one to one' => sub {

    before each => sub {
        TestEnv->prepare_table('book');
        TestEnv->prepare_table('book_description');
    };

    it 'throws when trying to create multiple objects' => sub {
        my $book = Book->new(title => 'fiction')->create;

        like exception {
            $book->create_related('description',
                [{description => 'Crap'}, {description => 'Nice'}]);
        }, qr/cannot create multiple related objects in one to one/;
    };

    it 'throws when there is already a related object' => sub {
        my $book = Book->new(title => 'fiction')->create;
        $book->create_related('description', description => 'Crap');

        like exception {
            $book->create_related('description', description => 'Crap');
        }, qr/Related object is already created/;
    };

    it 'sets correct values on new' => sub {
        my $book = Book->new(
            title       => 'Crap',
            description => {description => 'Crap'}
        );

        my $description = $book->related('description');

        is($description->get_column('description'), 'Crap');
    };

    it 'sets correct values on create' => sub {
        my $book = Book->new(
            title       => 'Crap',
            description => {description => 'Crap'}
        )->create;

        my $description = $book->related('description');

        is($description->get_column('description'), 'Crap');
    };

    it 'create_related' => sub {
        my $book = Book->new(title => 'fiction')->create;
        $book->create_related('description', description => 'Crap');

        is($book->related('description')->get_column('description'), 'Crap');
    };

    it 'updates related object it if is already created' => sub {
        my $description = BookDescription->new(description => 'Crap')->create;

        my $book = Book->new(title => 'fiction')->create;
        $book->create_related('description', $description);

        is($description->get_column('id'), $book->get_column('id'));
    };

    it 'create_related_from_object' => sub {
        my $book = Book->new(title => 'fiction')->create;
        $book->create_related('description',
            BookDescription->new(description => 'Crap'));

        my $description = BookDescription->table->find(
            first => 1,
            where => [book_id => $book->get_column('id')]
        );
        is($description->get_column('description'), 'Crap');
    };

    it 'find_related' => sub {
        my $book = Book->new(title => 'fiction')->create;
        my $description = BookDescription->new(
            description => 'Crap',
            book_id     => $book->get_column('id')
        )->create;

        $book = Book->new(id => $book->get_column('id'))->load;

        $description = $book->find_related('description');

        is($description->get_column('description'), 'Crap');
    };

    it 'updated_related' => sub {
        my $book = Book->new(title => 'fiction')->create;
        my $description = BookDescription->new(
            description => 'Crap',
            book_id     => $book->get_column('id')
        )->create;

        $book = Book->new(id => $book->get_column('id'))->load;

        $book->update_related('description', set => {description => 'Good'});

        $book =
          Book->new(id => $book->get_column('id'))->load(with => 'description');

        is($book->related('description')->get_column('description'), 'Good');
    };

    it 'delete_related' => sub {
        my $book = Book->new(title => 'fiction')->create;
        $book->create_related('description', description => 'Crap');

        $book->delete_related('description');

        ok(!$book->related('description'));
    };

};

runtests unless caller;
