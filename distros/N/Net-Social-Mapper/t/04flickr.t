#!perl -w 

use strict;
use Test::More;

my $tests = 1;
$tests   += 22 if $ENV{NET_SOCIAL_MAPPER_NETWORK_TESTS};
plan tests => $tests;

use_ok("Net::Social::Mapper::Persona::Flickr");

exit 0 unless $ENV{NET_SOCIAL_MAPPER_NETWORK_TESTS};

my $mapper;
use_ok("Net::Social::Mapper");
ok($mapper = Net::Social::Mapper->new,                              'Got mapper');
my $persona;
ok($persona  = $mapper->persona('daveman692', 'flickr'),            'Retrieved persona');
is($persona->user,      'daveman692',                               'Got user');
is($persona->service,   'flickr',                                   'Got service');
is($persona->domain,    'flickr.com',                               'Got domain');
is($persona->id,        '36381329@N00',                             'Got id');
is($persona->full_name, 'David Recordon',                           'Got name');
is($persona->homepage,  'http://www.flickr.com/photos/daveman692/', 'Got homepage'); 
is($persona->profile,   'http://www.flickr.com/people/daveman692/', 'Got homepage'); 
ok($persona->photo,                                                 'Got a photo');
is(scalar($persona->feeds), 2,                                      'Got correct number of feeds');

ok($persona  = $mapper->persona('36381329@N00', 'flickr'),          'Retrieved persona');
is($persona->user,      'daveman692',                               'Got user');
is($persona->service,   'flickr',                                   'Got service');
is($persona->domain,    'flickr.com',                               'Got domain');
is($persona->id,        '36381329@N00',                             'Got id');
is($persona->full_name, 'David Recordon',                           'Got name');
is($persona->homepage,  'http://www.flickr.com/photos/daveman692/', 'Got homepage'); 
is($persona->profile,   'http://www.flickr.com/people/daveman692/', 'Got homepage'); 
ok($persona->photo,                                                 'Got a photo');
is(scalar($persona->feeds), 2,                                      'Got correct number of feeds');

