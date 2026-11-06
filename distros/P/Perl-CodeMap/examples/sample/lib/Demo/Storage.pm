package Demo::Storage;
use strict;
use warnings;
use Demo::Config;
use Demo::Logger;

# Retrieve a sample record.
sub fetch {
    my ($id) = @_;
    return { id => $id, active => 1 };
}

# Simulate saving a record without I/O.
sub save {
    my ($item) = @_;
    return !!$item;
}
1;
