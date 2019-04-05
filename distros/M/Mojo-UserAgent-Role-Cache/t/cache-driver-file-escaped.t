use Mojo::Base -strict;
use Test::More;
use Mojo::UserAgent;

# key is cached url and value is file on disk
my %urls = (

  # empty query == 0d8dace6fe76cd029002e9691c7183d2
  'https://example.com' => 'example.com/0d8dace6fe76cd029002e9691c7183d2.http',

  # ?q= in query does not collied
  'https://example.com?q='    => 'example.com/15c83f8b82648565e0669950732ec70f.http',
  'https://example.com?%3fq=' => 'example.com/cb995bc34fd702b66ec5e2bfaeae37b7.http',

  # path part is less than 100 chars, so keeping it as is
  'https://example.com/123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789'
    => 'example.com/123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789/0d8dace6fe76cd029002e9691c7183d2.http',

  # path part is 100 chars long, so converting into checksum
  'https://example.com/1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890'
    => 'example.com/49cb3608e2b33fad6b65df8cb8f49668/0d8dace6fe76cd029002e9691c7183d2.http',

  # path is 32 chars long, so need to calculage checksum, since md5 is also 32 chars long
  'https://example.com/22502714af3afeb14cac9823cb91c6cb' =>
    'example.com/53e6c48eb3cf77f55c02520576dcc987/0d8dace6fe76cd029002e9691c7183d2.http',

  # checking that different versions of "search" does not collide
  'https://example.com/s-e-a-r-c-h_'         => 'example.com/s-e-a-r-c-h_5F/0d8dace6fe76cd029002e9691c7183d2.http',
  'https://example.com/search'               => 'example.com/search/0d8dace6fe76cd029002e9691c7183d2.http',
  'https://example.com/search/search'        => 'example.com/search/search/0d8dace6fe76cd029002e9691c7183d2.http',
  'https://example.com/search/search?search' => 'example.com/search/search/b1c9e435fa5846a2f99e1f43285ff8f2.http',
  'https://example.com/search?search'        => 'example.com/search/b1c9e435fa5846a2f99e1f43285ff8f2.http',
  'https://example.com/search?x=a%20b'       => 'example.com/search/f4922969db3053fc129382038aa63ed5.http',
  'https://example.com/search?x=a+b'         => 'example.com/search/fa90d25a69e3fda9dfb8d20c6c10758b.http',
  'https://example.com/_search/sear ch'      => 'example.com/_5Fsearch/sear_20ch/0d8dace6fe76cd029002e9691c7183d2.http',
  'https://example.com/_s_earch?[search]'    => 'example.com/_5Fs_5Fearch/51f89d6cdf2bacc02e01587f5295e2ab.http',
  'https://example.com?_s_earch'             => 'example.com/22502714af3afeb14cac9823cb91c6cb.http',
);

my $ua     = Mojo::UserAgent->with_roles('+Cache')->new;
my $driver = $ua->cache_driver;

for my $url (sort keys %urls) {
  is $driver->get(_key(post => $url)), undef, "undef $url";
  is $driver->set(_key(post => $url), "POST $url\n"), $driver, "set $url";
  is $driver->get(_key(post => $url)), "POST $url\n", "get after set $url";

  my $re = $urls{$url} . '$';
  $re =~ s!\.!\\.!g;
  $re =~ s!/!\\b.+?\\b!g;
  my @file = grep {m!$re!} Mojo::File->new($driver->root_dir)->list_tree->each;
  ok $file[0], "file $urls{$url}";
}

note 'testing variations of request';
is $driver->get(_key(post => 'https://example.com/')),   "POST https://example.com\n", 'ignore slash';
is $driver->get(_key(post => 'https://example.com/')),   "POST https://example.com\n", 'ignore slash';
is $driver->get(_key(post => 'http://example.com/')),    "POST https://example.com\n", 'ignore scheme';
is $driver->get(_key(post => 'http://example.com:80/')), "POST https://example.com\n", 'ignore port';
is $driver->get(_key(post => 'https://example.com/_search/sear%20ch')), "POST https://example.com/_search/sear ch\n",
  'escaped path';

note 'testing body';
is $driver->get(_key(post => 'https://example.com/', 'search')),    undef, 'body has different key';
is $driver->get(_key(post => 'https://example.com/', '?q=search')), undef, 'body hack does not collide';

done_testing;

sub _key {
  my $tx = Mojo::Transaction::HTTP->new;
  $tx->req->method(shift);
  $tx->req->url(Mojo::URL->new(shift));
  $tx->req->body(shift) if @_;
  return $ua->cache_key->($tx);
}
