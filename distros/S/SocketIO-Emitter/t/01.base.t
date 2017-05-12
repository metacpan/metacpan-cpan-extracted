use strict;
use warnings;
use SocketIO::Emitter;
use Test::More;

SKIP: {
    skip 'skip base test', 1 unless $ENV{SOCKETO_EMITTER_REDIS_TEST};

    my $ioe = SocketIO::Emitter->new();
    # basic
    {
        is_deeply(
            $ioe->pack('event', 'event message'),
            [
                'emitter',
                {
                    'data' => [
                        'event',
                        'event message'
                    ],
                    'type' => 2,
                    'nsp' => undef
                },
                {
                  'rooms' => [],
                  'flags' => {}
                }
            ]
        );
        $ioe->clear;
    }
    
    # namespace
    {
        is_deeply(
            $ioe->of('/nsp')->pack('event nsp', 'event nsp message'),
            [
                'emitter',
                {
                    'data' => [
                        'event nsp',
                        'event nsp message'
                    ],
                    'type' => 2,
                    'nsp' => '/nsp'
                },
                {
                  'rooms' => [],
                  'flags' => {}
                }
            ]
        );
        $ioe->clear;
    }
    
    # namespace + room
    {
        is_deeply(
            $ioe->of('/nsp')->to('some room')->pack('event nsp room', 'event nsp room message'),
            [
                'emitter',
                {
                    'data' => [
                        'event nsp room',
                        'event nsp room message'
                    ],
                    'type' => 2,
                    'nsp' => '/nsp'
                },
                {
                  'rooms' => ['some room'],
                  'flags' => {}
                }
            ]
        );
        $ioe->clear;
    }
    
    # broadcast
    {
        is_deeply(
            $ioe->broadcast->pack('event broadcast', 'event broadcast message'),
            [
                'emitter',
                {
                    'data' => [
                        'event broadcast',
                        'event broadcast message'
                    ],
                    'type' => 2,
                    'nsp' => undef
                },
                {
                  'rooms' => [],
                  'flags' => {
                      'broadcast' => 1,
                  }
                }
            ]
        );
        $ioe->clear;
    }
    
    # volatile
    {
        is_deeply(
            $ioe->volatile->pack('event volatile', 'event volatile message'),
            [
                'emitter',
                {
                    'data' => [
                        'event volatile',
                        'event volatile message'
                    ],
                    'type' => 2,
                    'nsp' => undef
                },
                {
                  'rooms' => [],
                  'flags' => {
                      'volatile' => 1,
                  }
                }
            ]
        );
        $ioe->clear;
    }
    
    # json
    {
        is_deeply(
            $ioe->json->pack('event json', 'event json message'),
            [
                'emitter',
                {
                    'data' => [
                        'event json',
                        'event json message'
                    ],
                    'type' => 2,
                    'nsp' => undef
                },
                {
                  'rooms' => [],
                  'flags' => {
                      'json' => 1,
                  }
                }
            ]
        );
        $ioe->clear;
    }
    
    # binary
    {
        my $bin = pack("CCC", 65, 66, 67);
        is_deeply(
            $ioe->pack('event binary', $bin),
            [
                'emitter',
                {
                    'data' => [
                        'event binary',
                        'ABC'
                    ],
                    'type' => 2,
                    'nsp' => undef
                },
                {
                  'rooms' => [],
                  'flags' => {}
                }
            ]
        );
        $ioe->clear;
    }
}

done_testing;
