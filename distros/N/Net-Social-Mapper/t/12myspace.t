use strict;
use lib qw(dev-local-lib cpan-lib);
use Net::Social::Mapper;
use Test::More;

my $tests = 1;
$tests   += 47 if $ENV{NET_SOCIAL_MAPPER_NETWORK_TESTS};
plan tests => $tests;

use_ok("Net::Social::Mapper::Persona::Myspace");

exit 0 unless $ENV{NET_SOCIAL_MAPPER_NETWORK_TESTS};

my $mapper;
use_ok("Net::Social::Mapper");
ok($mapper = Net::Social::Mapper->new,                              'Got mapper');
my $persona;
ok($persona  = $mapper->persona('bcomplexdnb', 'myspace'),          'Retrieved persona');
is($persona->user,      'bcomplexdnb',                              'Got user');
is($persona->service,   'myspace',                                  'Got service');
is($persona->domain,    'myspace.com',                              'Got domain');
is($persona->id,        '68998533',                                 'Got id');
is($persona->homepage,  'http://myspace.com/bcomplexdnb',           'Got homepage'); 
is($persona->profile,   'http://myspace.com/bcomplexdnb',           'Got profile'); 
is(scalar($persona->feeds), 1,                                      'Got correct number of feeds');
is(($persona->feeds)[0], 'http://blogs.myspace.com/Modules/BlogV2/Pages/RssFeed.aspx?friendID=68998533', 'Got correct feed');

ok($persona  = $mapper->persona('68998533', 'myspace'),             'Retrieved persona');
is($persona->user,      '68998533',                                 'Got user');
is($persona->service,   'myspace',                                  'Got service');
is($persona->domain,    'myspace.com',                              'Got domain');
is($persona->id,        '68998533',                                 'Got id');
is($persona->homepage,  'http://myspace.com/68998533',              'Got homepage'); 
is($persona->profile,   'http://myspace.com/68998533',              'Got profile'); 
is(scalar($persona->feeds), 1,                                      'Got correct number of feeds');
is(($persona->feeds)[0], 'http://blogs.myspace.com/Modules/BlogV2/Pages/RssFeed.aspx?friendID=68998533', 'Got correct feed');

ok($persona  = $mapper->persona('http://www.myspace.com/bcomplexdnb'), 'Retrieved persona from url with username');
is($persona->user,      'bcomplexdnb',                              'Got user');
is($persona->service,   'myspace',                                  'Got service');
is($persona->domain,    'myspace.com',                              'Got domain');
is($persona->id,        '68998533',                                 'Got id');
is($persona->homepage,  'http://myspace.com/bcomplexdnb',           'Got homepage'); 
is($persona->profile,   'http://myspace.com/bcomplexdnb',           'Got profile'); 
is(scalar($persona->feeds), 1,                                      'Got correct number of feeds');
is(($persona->feeds)[0], 'http://blogs.myspace.com/Modules/BlogV2/Pages/RssFeed.aspx?friendID=68998533', 'Got correct feed');

ok($persona  = $mapper->persona('http://www.myspace.com/68998533'),             'Retrieved persona from url with user id');
is($persona->user,      '68998533',                                 'Got user');
is($persona->service,   'myspace',                                  'Got service');
is($persona->domain,    'myspace.com',                              'Got domain');
is($persona->id,        '68998533',                                 'Got id');
is($persona->homepage,  'http://myspace.com/68998533',              'Got homepage'); 
is($persona->profile,   'http://myspace.com/68998533',              'Got profile'); 
is(scalar($persona->feeds), 1,                                      'Got correct number of feeds');
is(($persona->feeds)[0], 'http://blogs.myspace.com/Modules/BlogV2/Pages/RssFeed.aspx?friendID=68998533', 'Got correct feed');

ok($persona  = $mapper->persona('http://blogs.myspace.com/Modules/BlogV2/Pages/RssFeed.aspx?friendID=68998533'), 'Retrieved persona from feed url');
is($persona->user,      '68998533',                                 'Got user');
is($persona->service,   'myspace',                                  'Got service');
is($persona->domain,    'myspace.com',                              'Got domain');
is($persona->id,        '68998533',                                 'Got id');
is($persona->homepage,  'http://myspace.com/68998533',              'Got homepage'); 
is($persona->profile,   'http://myspace.com/68998533',              'Got profile'); 
is(scalar($persona->feeds), 1,                                      'Got correct number of feeds');
is(($persona->feeds)[0], 'http://blogs.myspace.com/Modules/BlogV2/Pages/RssFeed.aspx?friendID=68998533', 'Got correct feed');



