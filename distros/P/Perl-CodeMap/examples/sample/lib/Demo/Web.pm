package Demo::Web;
use strict;
use warnings;
use Demo::Auth;
use Demo::Storage;
use Demo::Logger;

# Create a new web entrypoint.
sub new {
    my ($class) = @_;
    return bless {}, $class;
}

sub run {
    return Demo::Storage::fetch('sample');
}
1;
