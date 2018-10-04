use Mojo::Base -strict;
use Test::More;
use Mojo::UserAgent;

$ENV{MOJO_USERAGENT_CACHE_STRATEGY} = 'DEFAULT=playback_or_record&GET=playback&POST=passthrough';

my $strategy = Mojo::UserAgent->with_roles('+Cache')->new->cache_strategy;
my $tx       = Mojo::Transaction::HTTP->new;

$tx->req->method('GET');
is $strategy->($tx), 'playback', 'get';

$tx->req->method('POST');
is $strategy->($tx), 'passthrough', 'post';

$tx->req->method('PUT');
is $strategy->($tx), 'playback_or_record', 'put';

$ENV{MOJO_USERAGENT_CACHE_STRATEGY} = 'DEFAULT=xyz';
my $ua = Mojo::UserAgent->with_roles('+Cache')->new;
eval { $ua->get('https://mojolicious.org') };
like $@, qr{Invalid strategy "xyz"}, 'invalid strategy';

done_testing;
