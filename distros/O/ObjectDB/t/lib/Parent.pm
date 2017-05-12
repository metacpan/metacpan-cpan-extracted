package Parent;

use strict;
use warnings;

use base 'Person';

__PACKAGE__->meta->add_column('age');
__PACKAGE__->meta->add_relationship(
    'books' => {
        type  => 'one to many',
        class => 'Book',
        map   => { id => 'author_id' }
    }
);

1;
