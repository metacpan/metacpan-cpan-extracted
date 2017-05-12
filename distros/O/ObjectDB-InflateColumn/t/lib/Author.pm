package Author;

use strict;
use warnings;

use base 'TestDB';

__PACKAGE__->schema(
    table          => 'author',
    columns        => [qw/id name password data/],
    primary_keys   => ['id'],
    auto_increment => 'id',
    unique_keys    => 'name'
);

    use JSON;
    my $json = JSON->new;
    
    # describe infalte
    __PACKAGE__->schema->inflate_column(
        'data', 
        {
            inflate => sub { $json->allow_nonref->encode($_[0]) },
            deflate => sub { $json->utf8(1)->decode($_[0]) },
        }
    );

1;
