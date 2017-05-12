#!perl -w

use strict;
use Test::More;

my $tests  = 25;
plan tests => $tests;

my $persona;
use_ok("Net::Social::Mapper::Persona::Email");
ok($persona = Net::Social::Mapper::Persona::Email->new('test@example.com', 'email'), "Created new persona");
is($persona->user,    'test@example.com',                      'Got user');
is($persona->service, 'email',                                 'Got service');
is($persona->domain,  'example.com',                           'Got domain');
is($persona->id,      'test',                                  'Got id');


my $mapper;
use_ok("Net::Social::Mapper");
ok($mapper = Net::Social::Mapper->new,                         'Got mapper');
ok($persona  = $mapper->persona('test@example.com'),           'Retrieved persona');
is($persona->user,      'test@example.com',                    'Got user');
is($persona->service,   'email',                               'Got service');
is($persona->domain,    'example.com',                         'Got domain');
is($persona->id,        'test',                                'Got id');

ok($persona  = $mapper->persona('Testy <test@example.com>'),   'Retrieved persona');
is($persona->user,      'test@example.com',                    'Got user');
is($persona->service,   'email',                               'Got service');
is($persona->domain,    'example.com',                         'Got domain');
is($persona->id,        'test',                                'Got id');
is($persona->full_name, 'Testy',                               'Got full name');

my @feeds;
@feeds = $persona->feeds;
is(scalar(@feeds), 0,                                          'Got correct number of feeds');

ok($persona  = $mapper->persona('muttley@last.fm'),            'Got persona');
is($persona->user,      'muttley',                             'Got user');
is($persona->service,   'last.fm',                             'Got service');
is($persona->domain,    'last.fm',                             'Got domain');

@feeds = $persona->feeds;
is(scalar(@feeds), 1,                                          'Got correct number of feeds');


