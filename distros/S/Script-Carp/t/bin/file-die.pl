use Script::Carp;

Script::Carp->setup(-file => './t/tmp/error_log.txt');

eval {
  die "# 123", "456789";
};
