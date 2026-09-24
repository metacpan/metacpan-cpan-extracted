#!/usr/bin/env perl
use warnings;

use Test2::Require::Module 'Mango';
use Test2::Require::Module 'Test::Mock::Mango';
use Test2::Require::Module 'Mojolicious';
use Test2::V0 -target => 'OpenTelemetry::Instrumentation::Mango';
use experimental 'signatures';

use Feature::Compat::Try;
use Mango;
use Mango::BSON 'bson_doc';
use Test::Mock::Mango;    # stubs Mango::new / Mango::db; must load before install
use OpenTelemetry;
use OpenTelemetry::Constants -span;

my $span;
my $otel = mock OpenTelemetry => override => [
    tracer_provider => sub {
        mock {} => add => [
            tracer => sub {
                mock {} => add => [
                    create_span => sub ( $, %args ) {
                        $span = mock { otel => \%args } => add => [
                            set_attribute => sub ( $self, %args ) {
                                $self->{otel}{attributes} = {
                                    %{ $self->{otel}{attributes} // {} },
                                    %args,
                                };
                            },
                            set_status => sub ( $self, $status, $desc = '' ) {
                                return if defined $self->{otel}{status};

                                $self->{otel}{status} = {
                                    code => $status,
                                    $desc ? ( description => $desc ) : (),
                                };
                            },
                            record_exception => sub ( $self, $e, %attributes ) {
                                push @{ $self->{otel}{exceptions} //= [] }, {
                                    exception  => $e,
                                    attributes => \%attributes,
                                };
                            },
                            end => sub ( $self ) {
                                $self->{otel}{ended} = 1;
                            },
                        ];
                    },
                ];
            },
        ];
    },
];

is [ CLASS->dependencies ], ['Mango'], 'Reports dependencies';

subtest Install => sub {
    CLASS->uninstall;

    is +CLASS->install, T, 'Installed modifier';
    is +CLASS->install, F, 'Installed modifier once';
};

subtest Command => sub {
    my $mango = Mango->new;
    $mango->hosts( [ ['localhost', 27017] ] );
    my $db = Mango::Database->new( mango => $mango, name => 'test' );

    subtest 'Blocking succeeds' => sub {
        my $m = mock $mango, override => [
            query => sub { { docs => [ { ok => 1, nonce => 'x' } ] } },
        ];

        my $reply = $db->command( bson_doc(getnonce => 1) );

        is $reply->{nonce}, 'x', 'got reply';
        is $span->{otel}, {
            status     => { code => SPAN_STATUS_OK },
            ended      => T,
            kind       => SPAN_KIND_CLIENT,
            name       => 'getnonce test',
            attributes => {
                'db.system.name'     => 'mongodb',
                'db.namespace'       => 'test',
                'db.operation.name'  => 'getnonce',
                'db.statement'       => '{"getnonce":1}',
                'server.address'     => 'localhost',
                'server.port'        => 27017,
            },
        }, 'Captured command data';
    };

    subtest 'Blocking dies' => sub {
        $span = undef;
        my $m = mock $mango, override => [
            query => sub { die "boom\nat somewhere line 3." },
        ];

        like dies { $db->command( bson_doc(getnonce => 1) ) },
            qr/boom/, 'Exception propagates';

        is $span->{otel}, {
            exceptions => [
                {
                    exception  => match qr/^boom/,
                    attributes => {},
                },
            ],
            status     => {
                code        => SPAN_STATUS_ERROR,
                description => 'boom',
            },
            ended      => T,
            kind       => SPAN_KIND_CLIENT,
            name       => 'getnonce test',
            attributes => {
                'db.system.name'    => 'mongodb',
                'db.namespace'      => 'test',
                'db.operation.name' => 'getnonce',
                'db.statement'      => '{"getnonce":1}',
                'server.address'    => 'localhost',
                'server.port'       => 27017,
            },
        }, 'Captured exception';
    };

    subtest 'Non-blocking fails' => sub {
        $span = undef;
        my $m = mock $mango, override => [
            query => sub { my $cb = pop; $cb->( shift, 'oh noes', undef ) },
        ];

        my ( $err, $loop ) = ( undef, $mango->ioloop );
        $loop->next_tick( sub {
            $db->command( bson_doc(getnonce => 1) => sub {
                ( undef, $err ) = @_[ 0, 1 ];
                $loop->stop;
            } );
        } );
        $loop->start;

        is $err, 'oh noes', 'Callback received error';
        is $span->{otel}, {
            status     => {
                code        => SPAN_STATUS_ERROR,
                description => 'oh noes',
            },
            ended      => T,
            kind       => SPAN_KIND_CLIENT,
            name       => 'getnonce test',
            attributes => {
                'db.system.name'    => 'mongodb',
                'db.namespace'      => 'test',
                'db.operation.name' => 'getnonce',
                'db.statement'      => '{"getnonce":1}',
                'server.address'    => 'localhost',
                'server.port'       => 27017,
            },
        }, 'Captured error';
    };

    subtest 'Non-blocking succeeds' => sub {
        $span = undef;
        my $m = mock $mango, override => [
            query => sub {
                my $cb = pop;
                $cb->( shift, undef, { docs => [ { ok => 1 } ] } );
            },
        ];

        my ( $doc, $loop ) = ( undef, $mango->ioloop );
        $loop->next_tick( sub {
            $db->command( bson_doc(getnonce => 1) => sub {
                ( undef, $doc ) = @_[ 1, 2 ];
                $loop->stop;
            } );
        } );
        $loop->start;

        is $doc->{ok}, 1, 'Callback received document';
        is $span->{otel}, {
            status     => { code => SPAN_STATUS_OK },
            ended      => T,
            kind       => SPAN_KIND_CLIENT,
            name       => 'getnonce test',
            attributes => {
                'db.system.name'    => 'mongodb',
                'db.namespace'      => 'test',
                'db.operation.name' => 'getnonce',
                'db.statement'      => '{"getnonce":1}',
                'server.address'    => 'localhost',
                'server.port'       => 27017,
            },
        }, 'Captured success';
    };

    subtest 'Non-blocking deferred callback' => sub {
        $span = undef;
        my $loop = $mango->ioloop;
        my $m = mock $mango, override => [
            query => sub {
                my $cb = pop;
                $loop->next_tick(
                    sub { $cb->( undef, undef, { docs => [ { ok => 1 } ] } ) } );
                return ();
            },
        ];

        my $doc;
        $loop->next_tick( sub {
            $db->command( bson_doc(getnonce => 1) => sub {
                ( undef, $doc ) = @_[ 1, 2 ];
                $loop->stop;
            } );
        } );
        $loop->start;

        is $doc->{ok}, 1, 'Callback received document on a later tick';
        is $span->{otel}{ended}, T, 'Span ended by the deferred callback';
        is $span->{otel}{status}, { code => SPAN_STATUS_OK }, 'Status OK';
    };

    subtest 'Non-blocking callback dies' => sub {
        $span = undef;
        my $m = mock $mango, override => [
            query => sub {
                my $cb = pop;
                $cb->( shift, undef, { docs => [ { ok => 1 } ] } );
            },
        ];

        my ( $died, $loop ) = ( undef, $mango->ioloop );
        $loop->next_tick( sub {
            try {
                $db->command( bson_doc(getnonce => 1) => sub {
                    die "cb boom";
                } );
            }
            catch ($e) {
                $died = "$e";
            }
            $loop->stop;
        } );
        $loop->start;

        like $died, qr/cb boom/, 'Callback exception propagates';
        is $span->{otel}{ended}, T, 'Span still ended';
        is $span->{otel}{status}, { code => SPAN_STATUS_OK },
            'Status untouched by callback death';
        is $span->{otel}{exceptions}, U,
            'No exception recorded on the operation span';
    };
};

subtest 'Command names' => sub {
    my $mango = Mango->new;
    $mango->hosts( [ ['localhost', 27017] ] );
    my $db = Mango::Database->new( mango => $mango, name => 'test' );

    my $m = mock $mango, override => [
        query => sub { { docs => [ { ok => 1 } ] } },
    ];

    $db->command( bson_doc( mapreduce => 'foo', map => 'm', reduce => 'r' ) );

    is $span->{otel}{name}, 'mapreduce test.foo', 'mapreduce names the collection';
    is $span->{otel}{attributes}{'db.operation.name'}, 'mapreduce',
        'mapreduce operation';

    $db->command( bson_doc( listCollections => 1, filter => { name => 'foo' } ) );

    is $span->{otel}{name}, 'listCollections test',
        'listCollections is a db-level command';
    is $span->{otel}{attributes}{'db.operation.name'}, 'listCollections',
        'listCollections operation';
    is $span->{otel}{attributes}{'db.collection.name'}, U,
        'No collection for listCollections';

    $db->command( bson_doc( insert => ( 'y' x 120 ), documents => [ { a => 1 } ] ) );

    is length( $span->{otel}{name} ), 100, 'Span name truncated to 100 characters';

    $db->command( bson_doc( getnonce => 1, filler => ( 'x' x 600 ) ) );

    is length( $span->{otel}{attributes}{'db.statement'} ), 512,
        'Statement truncated to 512 characters';
};

subtest Find => sub {
    $span = undef;
    my $mango = Mango->new;
    $mango->hosts( [ ['localhost', 27017] ] );
    my $db  = Mango::Database->new( mango => $mango, name => 'test' );
    my $col = $db->collection('foo');

    my $m = mock $mango, override => [
        query => sub { { docs => [ { bar => 'baz' } ], cursor => 0 } },
    ];

    my $doc = $col->find({ bar => 'baz' })->next;

    is $doc->{bar}, 'baz', 'Got document';
    is $span->{otel}, {
        status     => { code => SPAN_STATUS_OK },
        ended      => T,
        kind       => SPAN_KIND_CLIENT,
        name       => 'find test.foo',
        attributes => {
            'db.system.name'     => 'mongodb',
            'db.namespace'       => 'test',
            'db.collection.name' => 'foo',
            'db.operation.name'  => 'find',
            'db.statement'       => '{"bar":"baz"}',
            'server.address'     => 'localhost',
            'server.port'        => 27017,
        },
    }, 'Captured find data';
};

subtest 'Wire operations' => sub {
    my $mango = Mango->new;
    $mango->hosts( [ ['localhost', 27017] ] );

    my $m = mock $mango, override => [
        _next => sub {
            my ( $self, $op ) = @_;
            return unless $op && $op->{cb};
            $op->{cb}->( $self, undef, { docs => [ { n => 1 } ], cursor => 0 } );
            return;
        },
    ];

    $mango->get_more( 'test.foo', 101, '1234' );

    is $span->{otel}, {
        status     => { code => SPAN_STATUS_OK },
        ended      => T,
        kind       => SPAN_KIND_CLIENT,
        name       => 'get_more test.foo',
        attributes => {
            'db.system.name'     => 'mongodb',
            'db.namespace'       => 'test',
            'db.collection.name' => 'foo',
            'db.operation.name'  => 'get_more',
            'server.address'     => 'localhost',
            'server.port'        => 27017,
        },
    }, 'Captured get_more data';

    $span = undef;

    $mango->kill_cursors('5899165064703300892');

    is $span->{otel}, {
        status     => { code => SPAN_STATUS_OK },
        ended      => T,
        kind       => SPAN_KIND_CLIENT,
        name       => 'kill_cursors 5899165064703300892',
        attributes => {
            'db.system.name'    => 'mongodb',
            'db.operation.name' => 'kill_cursors',
            'server.address'    => 'localhost',
            'server.port'       => 27017,
        },
    }, 'Captured kill_cursors data (cursor id stays out of db attributes)';
};

subtest Mock => sub {
    $span = undef;
    my $mango = Mango->new;
    my $col   = $mango->db('test')->collection('foo');

    subtest 'Blocking CRUD' => sub {
        # find_one ignores its query and returns the first fake document, so
        # drop the pre-seeded fake data to find what this subtest inserts
        $Test::Mock::Mango::data->{collection} = [];

        my $oid = $col->insert({ bar => 'baz' });

        is ref $oid, 'Mango::BSON::ObjectID', 'Got oid';
        is $span->{otel}, {
            status     => { code => SPAN_STATUS_OK },
            ended      => T,
            kind       => SPAN_KIND_CLIENT,
            name       => 'insert test.foo',
            attributes => {
                'db.system.name'     => 'mongodb',
                'db.namespace'       => 'test',
                'db.collection.name' => 'foo',
                'db.operation.name'  => 'insert',
            },
        }, 'Captured insert data';

        my $doc = $col->find_one($oid);

        is $doc->{bar}, 'baz', 'Got document';
        is $span->{otel}, {
            status     => { code => SPAN_STATUS_OK },
            ended      => T,
            kind       => SPAN_KIND_CLIENT,
            name       => 'find_one test.foo',
            attributes => {
                'db.system.name'     => 'mongodb',
                'db.namespace'       => 'test',
                'db.collection.name' => 'foo',
                'db.operation.name'  => 'find_one',
            },
        }, 'Captured find_one data';

        my $result = $col->update( { bar => 'baz' }, { '$set' => { bar => 'yada' } } );

        is $result->{n}, 1, 'Updated document';
        is $span->{otel}{name}, 'update test.foo', 'Captured update data';
        is $span->{otel}{attributes}, {
            'db.system.name'     => 'mongodb',
            'db.namespace'       => 'test',
            'db.collection.name' => 'foo',
            'db.operation.name'  => 'update',
        }, 'Update attributes';
        is $span->{otel}{status}, { code => SPAN_STATUS_OK }, 'Update status';

        $result = $col->remove( { bar => 'yada' }, { single => 1 } );

        is $result->{n}, 1, 'Removed document';
        is $span->{otel}{name}, 'remove test.foo', 'Captured remove data';
    };

    subtest 'Blocking cursors' => sub {
        my $docs = $col->find({ bar => 'baz' })->all;

        is scalar @$docs, 1, 'Got one document';
        is $span->{otel}, {
            status     => { code => SPAN_STATUS_OK },
            ended      => T,
            kind       => SPAN_KIND_CLIENT,
            name       => 'find',
            attributes => {
                'db.system.name'    => 'mongodb',
                'db.operation.name' => 'find',
            },
        }, 'Captured find data (mock cursors carry no collection)';

        my $cursor = $col->find;
        $cursor->next;
        $cursor->next;

        is $span->{otel}{name}, 'find', 'Each next is a find span';

        my $count = $col->find->count;

        is $count, T, 'Got count';
        is $span->{otel}{name}, 'count', 'Captured count data';
        is $span->{otel}{attributes}{'db.operation.name'}, 'count', 'Count operation';
    };

    subtest 'Remaining operations' => sub {
        $span = undef;
        $col->aggregate([]);

        is $span->{otel}{name}, 'aggregate test.foo', 'Captured aggregate data';
        is $span->{otel}{attributes}, {
            'db.system.name'     => 'mongodb',
            'db.namespace'       => 'test',
            'db.collection.name' => 'foo',
            'db.operation.name'  => 'aggregate',
        }, 'Aggregate attributes';

        $span = undef;
        $col->create;

        is $span->{otel}{name}, 'create test.foo', 'Captured create data';
        is $span->{otel}{status}, { code => SPAN_STATUS_OK }, 'Create status';

        $span = undef;
        $col->find_and_modify(
            { query => { bar => 'baz' }, update => { '$set' => { bar => 'new' } } } );

        is $span->{otel}{name}, 'find_and_modify test.foo',
            'Captured find_and_modify data';

        $span = undef;
        $col->drop;

        is $span->{otel}{name}, 'drop test.foo', 'Captured drop data';
        is $span->{otel}{attributes}{'db.operation.name'}, 'drop', 'Drop operation';
    };

    subtest 'Blocking command' => sub {
        my $db = $mango->db('test');
        $db->command('getnonce');

        is $span->{otel}, {
            status     => { code => SPAN_STATUS_OK },
            ended      => T,
            kind       => SPAN_KIND_CLIENT,
            name       => 'getnonce test',
            attributes => {
                'db.system.name'    => 'mongodb',
                'db.namespace'      => 'test',
                'db.operation.name' => 'getnonce',
            },
        }, 'Captured command data';
    };

    subtest 'Non-blocking via Mojo::IOLoop' => sub {
        my $loop = $mango->ioloop;
        my $err;
        $loop->next_tick( sub {
            $col->insert({ bar => 'qux' } => sub {
                ( undef, $err ) = @_[ 0, 1 ];
                $loop->stop;
            } );
        } );
        $loop->start;

        is $err, U, 'No error';
        is $span->{otel}{name}, 'insert test.foo', 'Captured non-blocking insert data';
        is $span->{otel}{status}, { code => SPAN_STATUS_OK }, 'Non-blocking status';
        is $span->{otel}{ended}, T, 'Ended';
    };

    subtest 'Error state' => sub {
        my $loop = $mango->ioloop;
        my $err;
        $Test::Mock::Mango::error = 'oh noes!';
        $loop->next_tick( sub {
            $col->insert({ bar => 'quux' } => sub {
                ( undef, $err ) = @_[ 0, 1 ];
                $loop->stop;
            } );
        } );
        $loop->start;

        is $err, 'oh noes!', 'Callback received error';
        is $span->{otel}, {
            status     => {
                code        => SPAN_STATUS_ERROR,
                description => 'oh noes!',
            },
            ended      => T,
            kind       => SPAN_KIND_CLIENT,
            name       => 'insert test.foo',
            attributes => {
                'db.system.name'     => 'mongodb',
                'db.namespace'       => 'test',
                'db.collection.name' => 'foo',
                'db.operation.name'  => 'insert',
            },
        }, 'Captured error';
    };
};

subtest Uninstall => sub {
    $Test::Mock::Mango::error = undef;
    CLASS->uninstall;

    my $before = $span;
    Mango->new->db('test')->collection('foo')->insert({ bar => 'nope' });
    Mango->new->db('test')->command('getnonce');
    Mango->new->db('test')->collection('foo')->find->all;
    is $span, $before, 'No spans after uninstall';

    is +CLASS->install, T, 'Installed modifier again';

    Mango->new->db('test')->collection('foo')->insert({ bar => 'yada' });
    is $span->{otel}{name}, 'insert test.foo', 'Spans again after reinstall';
    is $span->{otel}{ended}, T, 'Ended';
};

done_testing;
