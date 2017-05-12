use Test::More tests => 2;


use_ok 'Rex::IO::Client';

my $o = Rex::IO::Client->create(version => 1);

ok(ref $o, "created client object");
