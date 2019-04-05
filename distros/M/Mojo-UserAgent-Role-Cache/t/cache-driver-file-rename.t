BEGIN { $ENV{MOJO_UA_CACHE_RENAME} = 1 }
use Mojo::Base -strict;
use Test::More;
use Mojo::Transaction::HTTP;
use Mojo::UserAgent;

my $ua     = Mojo::UserAgent->with_roles('+Cache')->new;
my $driver = $ua->cache_driver;

# Legacy path: .../:method/:host/:path_query
my $file = Mojo::File->new($driver->root_dir, 'post', '0a137b375cc3', '1c85cc3dbf7f.http');

plan skip_all => "Cannot create test file: $@" unless eval {
  Mojo::File->new($file->dirname)->make_path;
  $file->spurt("GET /file\r\n");
};

my $url
  = 'https://supergirl:for-testing@www.google.com/search?source=hp&ei=yXXXXXXzXXX00yXXz5XXXX&btnG=X%C3%B8y&q=mojolicious&gs_l=xyz-xy.3..0x000y0l0j0i00x00x0y0.000000.000000.0.000000.00.00.0.0.0.0.000.0000.0.0x0y0.0.0....0...0z.1.00.xyz-xy..00.0.0000.0..0.0.0xYZz00yZ0z';
is $driver->get(_key(post => $url)), "GET /file\r\n", 'get after set';
like +Mojo::File->new($driver->root_dir)->list_tree->first,
  qr{mojo-useragent-cache-.+?post.+?www\.google\.com.+?search.+?387ac59b94dc580badafa0ecf1a55510\.http},
  'renamed on disk';

done_testing;

sub _key {
  my $tx = Mojo::Transaction::HTTP->new;
  $tx->req->method(shift);
  $tx->req->url(Mojo::URL->new(shift));
  $tx->req->body(shift) if @_;
  return $ua->cache_key->($tx);
}
