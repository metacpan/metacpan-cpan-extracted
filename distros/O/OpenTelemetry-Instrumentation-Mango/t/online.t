use Mojo::Base -strict;

use Test2::Require::Module 'Mango';
use Test2::Require::Module 'OpenTelemetry';
use Test2::V0;
use experimental 'signatures';

skip_all 'set TEST_ONLINE to enable this test'
  unless $ENV{TEST_ONLINE};

use Feature::Compat::Try;
use Mango;
use Mango::BSON 'bson_doc';
use Mojo::IOLoop;
use OpenTelemetry;
use OpenTelemetry::Constants -span;
use OpenTelemetry::Instrumentation::Mango ();

# Capture every span the instrumentation creates
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

my ( $server_host, $server_port )
    = $ENV{TEST_ONLINE} =~ m{^mongodb://([^:/]+)(?::(\d+))?};
$server_port //= 27017;

OpenTelemetry::Instrumentation::Mango->install;

my $db_name = 'otel_mango_online_test';
my $mango   = Mango->new($ENV{TEST_ONLINE});
my $db      = $mango->db($db_name);
my $col     = $db->collection('online_test');

sub base_attributes {
    return (
        'db.system.name' => 'mongodb',
        'db.namespace'   => $db_name,
        'server.address' => $server_host,
        'server.port'    => $server_port,
    );
}

# Clean slate (the guard keeps this idempotent against a reused server)
$col->drop if $col->options;

# Insert documents blocking (command "insert")
my $oids = $col->insert( [ map { { n => $_ } } 1 .. 5 ] );
is scalar @$oids, 5, 'inserted five documents';
is $span->{otel}{name}, "insert $db_name.online_test", 'right insert span name';
is $span->{otel}{attributes}, {
    base_attributes(),
    'db.collection.name' => 'online_test',
    'db.operation.name'  => 'insert',
    'db.statement'       => match qr/"insert"/,
}, 'right insert span attributes';
is $span->{otel}{kind}, SPAN_KIND_CLIENT, 'right insert span kind';
is $span->{otel}{status}, { code => SPAN_STATUS_OK }, 'insert status is OK';
is $span->{otel}{ended}, T, 'insert span ended';

# Find one document blocking (OP_QUERY via the cursor, not a command)
my $doc = $col->find_one( $oids->[0] );
is $doc->{n}, 1, 'found the right document';
is $span->{otel}{name}, "find $db_name.online_test", 'right find_one span name';
is $span->{otel}{attributes}, {
    base_attributes(),
    'db.collection.name' => 'online_test',
    'db.operation.name'  => 'find',
    'db.statement'       => match qr/"_id"/,
}, 'right find_one span attributes';
is $span->{otel}{status}, { code => SPAN_STATUS_OK }, 'find_one status is OK';
is $span->{otel}{ended}, T, 'find_one span ended';

# Find all documents blocking: one "find" span followed by "get_more" spans
# for every extra batch
my $all = $col->find->batch_size(2)->all;
is scalar @$all, 5, 'found all five documents';
is $span->{otel}{name}, "get_more $db_name.online_test",
    'pagination produced a get_more span';
is $span->{otel}{attributes}, {
    base_attributes(),
    'db.collection.name' => 'online_test',
    'db.operation.name'  => 'get_more',
}, 'right get_more span attributes';
is $span->{otel}{status}, { code => SPAN_STATUS_OK }, 'get_more status is OK';
is $span->{otel}{ended}, T, 'get_more span ended';

# Update documents blocking (command "update")
my $result
    = $col->update( { n => { '$gt' => 0 } }, { '$set' => { done => 1 } },
    { multi => 1 } );
is $result->{n}, 5, 'updated five documents';
is $span->{otel}{name}, "update $db_name.online_test", 'right update span name';
is $span->{otel}{attributes}{'db.operation.name'}, 'update', 'update operation';
is $span->{otel}{status}, { code => SPAN_STATUS_OK }, 'update status is OK';

# Remove one document blocking (command "delete")
$result = $col->remove( { n => 1 }, { single => 1 } );
is $result->{n}, 1, 'removed one document';
is $span->{otel}{name}, "delete $db_name.online_test", 'right remove span name';
is $span->{otel}{attributes}{'db.operation.name'}, 'delete', 'delete operation';
is $span->{otel}{status}, { code => SPAN_STATUS_OK }, 'remove status is OK';

# Run a database-level command blocking (no collection target)
my $info = $db->command( bson_doc( buildInfo => 1 ) );
ok $info->{version}, 'ran buildInfo';
is $span->{otel}{name}, "buildInfo $db_name", 'right command span name';
is $span->{otel}{attributes}, {
    base_attributes(),
    'db.operation.name' => 'buildInfo',
    'db.statement'      => '{"buildInfo":1}',
}, 'right command span attributes';

# A failing command croaks and produces an error span
my ( $died, $error );
try {
    $db->command( bson_doc( totallyBogusCommand => 1 ) );
    $died = 0;
}
catch ($e) {
    ( $died, $error ) = ( 1, "$e" );
}
ok $died, 'bogus command croaks';
like $error, qr/totallyBogusCommand/i, 'error names the bogus command';
like $span->{otel}{exceptions}[0]{exception}, qr/totallyBogusCommand/i,
    'recorded exception names the bogus command';
is $span->{otel}{status}, {
    code        => SPAN_STATUS_ERROR,
    description => match qr/totallyBogusCommand/i,
}, 'command status is ERROR';
is $span->{otel}{ended}, T, 'error span ended';

# Run a command non-blocking: the span must end in the callback. Note that
# Mango drives non-blocking I/O through Mojo::IOLoop->singleton (the
# instrumentation never touches the loop), so we start it like mango's own
# tests do. Under a running Mojolicious app the singleton is already running.
$span = undef;
my $nb_doc;
$db->command( 'buildInfo' => sub {
    my ( $db, $err, $doc ) = @_;
    $nb_doc = $err ? undef : $doc;
    Mojo::IOLoop->stop;
} );
Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

ok $nb_doc->{version}, 'non-blocking command succeeded';
is $span->{otel}{name}, "buildInfo $db_name", 'right non-blocking span name';
is $span->{otel}{status}, { code => SPAN_STATUS_OK }, 'non-blocking status is OK';
is $span->{otel}{ended}, T, 'non-blocking span ended in the callback';

# Killing a live cursor produces a kill_cursors span: the cursor id stays in
# the name and out of the database attributes
my $cursor = $col->find->batch_size(2);
$cursor->next;
ok $cursor->id, 'cursor is live';
$cursor->rewind;

like $span->{otel}{name}, qr/^kill_cursors \d+$/, 'right kill_cursors span name';
is $span->{otel}{attributes}, {
    'db.system.name'    => 'mongodb',
    'db.operation.name' => 'kill_cursors',
    'server.address'    => $server_host,
    'server.port'       => $server_port,
}, 'kill_cursors keeps the cursor id out of db attributes';
is $span->{otel}{status}, { code => SPAN_STATUS_OK }, 'kill_cursors status is OK';
is $span->{otel}{ended}, T, 'kill_cursors span ended';

# Clean up
$db->command( bson_doc( dropDatabase => 1 ) );

done_testing;
