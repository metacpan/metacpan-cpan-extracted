use Mojo::Base -strict;
use Test::More;
use Mojo::UserAgent;

plan skip_all => 'TEST_ONLINE=1' unless $ENV{TEST_ONLINE};

my $url = 'https://mojolicious.org';
my $ua  = Mojo::UserAgent->with_roles('+Cache')->new;

my $error = $ua->get($url)->error;
ok !$error, 'get' or diag $error->{message};

$error = 'Not waited for';
$ua->get_p($url)->then(sub { $error = '' }, sub { $error = shift })->wait;
ok !$error, 'get_p' or diag $error;

my $file = Mojo::File->new($ua->cache_driver->root_dir)->list_tree->first;
like $file, qr{mojo-useragent-cache-.*get[^\w]+685364d6ec80[^\w]+d41d8cd98f00\.http}, 'get filename on disk';
unlink $file;

$url = 'https://www.thorsen.pm/dummy';
$ua->post($url, form => {name => 'batgirl'});
$file = Mojo::File->new($ua->cache_driver->root_dir)->list_tree->first;
like $file, qr{mojo-useragent-cache-.*post[^\w]+4e4df3906f8e[^\w]+938a5b1f7a73[^\w]+4e3ee9e128a9\.http},
  'post filename on disk';

done_testing;
