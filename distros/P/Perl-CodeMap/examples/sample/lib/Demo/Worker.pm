package Demo::Worker;
use strict;
use warnings;
use Demo::Queue;
use Demo::Storage;
use Demo::Logger;

# Process a queued message.
sub process {
    my ($class, $message) = @_;
    return Demo::Storage::save($message);
}
1;
