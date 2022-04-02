use Test::More;
use Perl::Server;
use Cwd;

my $server1 = Perl::Server->new('/foo');
is($server1->{path}, '/foo', 'Test path difined');

my $server2 = Perl::Server->new;
is($server2->{path}, getcwd, 'Test path current');

done_testing;
