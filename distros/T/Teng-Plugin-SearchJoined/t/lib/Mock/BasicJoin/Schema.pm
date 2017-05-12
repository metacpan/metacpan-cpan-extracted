package Mock::BasicJoin::Schema;
use strict;
use warnings;
use Teng::Schema::Declare;

table {
    name 'user';
    pk    qw/id/;
    columns qw/ id name/;
};

table {
    name 'user_item';
    pk    qw/id/;
    columns qw/ id user_id item_id /;
};

table {
    name 'item';
    pk    qw/id/;
    columns qw/ id name /;
};

1;
