
use v5.38;
use experimental qw( signatures );

use Protocol::OVSDB;
use Protocol::OVSDB::Monitor;
use IO::Async::Loop;
use IO::Async::Stream;


my $db;
my $loop = IO::Async::Loop->new;
my $stream = IO::Async::Stream->new(
    autoflush => 1,
    on_read => sub($self, $bufref, $eof) {
        if ($eof) { die "Connection closed\n" }

        say "received: $$bufref";
        $db->receive( $$bufref );
        $$bufref = '';
    });
$loop->add( $stream );
$db   = Protocol::OVSDB->new(
    on_send => sub {
        $stream->write( $_[0] );
        return;
    });
my $sock_f = $loop->connect(
    addr => {
        family => 'unix',
        socktype => 'stream',
        path => '/run/openvswitch/db.sock'
    },
    handle => $stream,
    on_connected => sub {
        $db->list_dbs(
            sub($dbs, $error) {
                $db->get_schema( 'Open_vSwitch', sub($schema, $err) {
                    say $_ for (keys $schema->{tables}->%*);
                });
            });
    },
    on_fail => sub {
        say "Failed to connect!";
        exit 1;
    });

$loop->run;
