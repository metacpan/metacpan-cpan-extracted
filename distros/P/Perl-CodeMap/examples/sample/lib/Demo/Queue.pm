package Demo::Queue;
use strict;
use warnings;
use Demo::Config;
use Demo::Logger;

# Produce a synthetic queued item.
sub next_item {
    return { id => 'demo' };
}
1;
