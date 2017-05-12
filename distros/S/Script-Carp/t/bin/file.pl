use Script::Carp;

Script::Carp->setup(-file => './t/tmp/error_log.txt');

die "123", "456789";



