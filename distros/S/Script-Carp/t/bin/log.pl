use Script::Carp;
use Carp;
Script::Carp->setup(-log => './t/tmp/error_log.txt', -ignore_eval);
sub x {
eval { die "123", "456789";};
eval { die "223", "456789";};
eval { die "323", "456789";};
eval { die "423", "456789";};
}

x();
