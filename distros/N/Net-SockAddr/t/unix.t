use 5.012;
use warnings;
use lib 't/lib';
use MyTest;

plan skip_all => 'AF_UNIX not supported on Windows' if $^O eq 'MSWin32';

catch_run('unix');

my $sa = Net::SockAddr::Unix->new("/my/path");
is(length($sa->path), length("/my/path"));
is($sa->path, "/my/path");
is($sa, "/my/path");

dies_ok { Net::SockAddr::Unix->new("path" x 1000) };

done_testing();
