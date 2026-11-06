package Demo::Adapters::Database;
use strict;
use warnings;
use parent 'Demo::Storage';

# Wrap the example storage layer.
sub connect {
    return 1;
}
1;
