use Test::More;
use Patro ':test';
use Scalar::Util 'reftype';
use 5.010;

my $main_pid = $$;
$SIG{ALRM} = sub { warn "SIGALRM! \@ ",scalar localtime; };

my $obj = sub { my ($x,$y) = @_; return ($x+$y) * ($x-$y) };

is($obj->(5,4), 9, 'local sub works');

ok($obj && (ref($obj) eq 'CODE' || ref($obj) eq 'CODE*'), 'create remote ref');
my $cfg = patronize($obj);
ok($cfg, 'got server config');

my ($proxy) = Patro->new($cfg)->getProxies;
ok($proxy, 'proxy as boolean');
ok(Patro::ref($proxy) =~ /^CODE/, 'remote ref')
    or diag "Patro::ref was ", Patro::ref($proxy);
ok(Patro::reftype($proxy) =~ /^CODE/, 'remote reftype');

is($proxy->(4,3), 7, 'proxy code access');

done_testing;


# TODO:
#  set a scalar-type object and perform method calls
#  set value to another reference
