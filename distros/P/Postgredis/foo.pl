
use v5.20;

my $str = q[PostgreSQL 9.4.5 on];

my ($major,$minor,$sub) = $str =~ /PostgreSQL ([0-9]+)\.([0-9]+)\.([0-9]+) /;
say "got $major, $minor, $sub";


