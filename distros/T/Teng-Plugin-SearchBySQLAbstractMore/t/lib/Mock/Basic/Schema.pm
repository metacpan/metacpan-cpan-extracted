package Mock::Basic::Schema;
use utf8;
use Teng::Schema::Declare;

table {
    name 'mock_basic';
    pk 'id';
    columns qw/
        id
        name
        delete_fg
    /;
};

table {
    name 'mock_basic2';
    pk 'id';
    columns qw/
        id
        mock_basic_id
        name
        delete_fg
    /;
};

1;

