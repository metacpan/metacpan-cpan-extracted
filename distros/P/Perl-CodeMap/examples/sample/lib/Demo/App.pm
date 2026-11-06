package Demo::App;
use strict;
use warnings;
use Demo::Web;
use Demo::Worker;
use Demo::Config;

# Start the sample service's components.
sub start {
    my ($class) = @_;
    return Demo::Web->new->run;
}

sub status {
    return 'running';
}
1;
