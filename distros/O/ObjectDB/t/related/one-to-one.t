use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Fatal;
use TestDBH;
use TestEnv;

use Book;
use BookDescription;

subtest 'throws when trying to create multiple objects' => sub {
    _setup();

    my $book = Book->new(title => 'fiction')->create;

    like exception {
        $book->create_related('description', [ { description => 'Crap' }, { description => 'Nice' } ]);
    }, qr/cannot create multiple related objects in one to one/;
};

subtest 'throws when there is already a related object' => sub {
    _setup();

    my $book = Book->new(title => 'fiction')->create;
    $book->create_related('description', description => 'Crap');

    like exception {
        $book->create_related('description', description => 'Crap');
    }, qr/Related object is already created/;
};

subtest 'sets correct values on new' => sub {
    _setup();

    my $book = Book->new(
        title       => 'Crap',
        description => { description => 'Crap' }
    );

    my $description = $book->related('description');

    is($description->get_column('description'), 'Crap');
};

subtest 'sets correct values on create' => sub {
    _setup();

    my $book = Book->new(
        title       => 'Crap',
        description => { description => 'Crap' }
    )->create;

    my $description = $book->related('description');

    is($description->get_column('description'), 'Crap');
};

subtest 'create_related' => sub {
    _setup();

    my $book = Book->new(title => 'fiction')->create;
    $book->create_related('description', description => 'Crap');

    is($book->related('description')->get_column('description'), 'Crap');
};

subtest 'updates related object subtest if is already created' => sub {
    _setup();

    my $description = BookDescription->new(description => 'Crap')->create;

    my $book = Book->new(title => 'fiction')->create;
    $book->create_related('description', $description);

    is($description->get_column('id'), $book->get_column('id'));
};

subtest 'create_related_from_object' => sub {
    _setup();

    my $book = Book->new(title => 'fiction')->create;
    $book->create_related('description', BookDescription->new(description => 'Crap'));

    my $description = BookDescription->table->find(
        first => 1,
        where => [ book_id => $book->get_column('id') ]
    );
    is($description->get_column('description'), 'Crap');
};

subtest 'find_related' => sub {
    _setup();

    my $book = Book->new(title => 'fiction')->create;
    my $description = BookDescription->new(
        description => 'Crap',
        book_id     => $book->get_column('id')
    )->create;

    $book = Book->new(id => $book->get_column('id'))->load;

    $description = $book->find_related('description');

    is($description->get_column('description'), 'Crap');
};

subtest 'updated_related' => sub {
    _setup();

    my $book = Book->new(title => 'fiction')->create;
    my $description = BookDescription->new(
        description => 'Crap',
        book_id     => $book->get_column('id')
    )->create;

    $book = Book->new(id => $book->get_column('id'))->load;

    $book->update_related('description', set => { description => 'Good' });

    $book =
      Book->new(id => $book->get_column('id'))->load(with => 'description');

    is($book->related('description')->get_column('description'), 'Good');
};

subtest 'delete_related' => sub {
    _setup();

    my $book = Book->new(title => 'fiction')->create;
    $book->create_related('description', description => 'Crap');

    $book->delete_related('description');

    ok(!$book->related('description'));
};

done_testing;

sub _setup {
    TestEnv->prepare_table('book');
    TestEnv->prepare_table('book_description');
}
