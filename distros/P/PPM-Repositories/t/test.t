use Test;
BEGIN { plan tests => 6 };
use PPM::Repositories qw(get list used_archs);
ok(1);

my @arch = used_archs();
print "# $_\n" for @arch;
ok(grep(/^MSWin32/, @arch) > 1);

my @list = list("MSWin32-x86-multi-thread-5.8");
print "# $_\n" for @list;
ok(grep(/^activestate$/, @list));

my %repo = get("activestate", "MSWin32-x86-multi-thread-5.8");
printf("# %-12s %s\n", $_, $repo{$_}) for sort keys %repo;
ok($repo{desc} =~ /activestate/i);
ok($repo{home} =~ /activestate.com/i);
ok($repo{packlist} =~ /ppm4.activestate.com/i);


