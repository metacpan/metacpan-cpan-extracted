use Test::More;
use Carp 'verbose';
use Patro ':test';
use strict;
use warnings;

my $x = { abc => "xyz", def => "foo", foo => 123,
	   ghi => { jkl => [ 'm','n','o','p',['qrs','tuv']],
		    wxy => 123 } };

# exercise all of the different ways to retrieve the
# proxies from the server

my $c0 = patronize($x);

my $c1 = $c0->to_string;
$c0->to_file('c2');

my $y0 = getProxies($c0);
my $y1 = getProxies($c1);
my $y2 = getProxies('c2');
my $y3 = Patro->new($c0)->getProxies;
my $y4 = Patro->new($c1)->getProxies;
my $y5 = Patro->new('c2')->getProxies;

ok(123 == eval { $y0->{foo} }, 'getProxies direct from Config');
ok(123 == eval { $y1->{foo} }, 'getProxies direct from string');
ok(123 == eval { $y2->{foo} }, 'getProxies direct from file');
ok(123 == eval { $y3->{foo} }, 'getProxies from Patro, Config');
ok(123 == eval { $y4->{foo} }, 'getProxies from Patro, string');
ok(123 == eval { $y5->{foo} }, 'getProxies from Patro, file');

done_testing;

unlink('c2');
