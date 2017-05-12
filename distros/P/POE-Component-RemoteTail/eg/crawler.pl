# ------------------------------------------------
# sample crawler script from log.
# ------------------------------------------------
#    PoCo::RemoteTail
#            -> HTTP::Request::FromLog
#                          -> PoCo::Client::HTTP
# ------------------------------------------------

use strict;
use POE;
use POE::Component::Client::Keepalive;
use POE::Component::Client::HTTP;
use POE::Component::RemoteTail;
use HTTP::Request::FromLog;

my $from_host = "web_server";
my $path      = '/logs/access_log';
my $user      = 'hoge';
my $password  = 'fuga';

my $to_host = 'target_server';

# ------------------------------------------------
my $pool = POE::Component::Client::Keepalive->new(
    keep_alive   => 120,
    max_open     => 10,
    max_per_host => 10,
    timeout      => 60,
);

POE::Component::Client::HTTP->spawn(
    Alias             => 'ua',
    Timeout           => 10,
    ConnectionManager => $pool
);

my $tailer = POE::Component::RemoteTail->spawn();

my $job = $tailer->job(
    host => $from_host,
    path => $path,
    user => $user,
);

POE::Session->create(
    inline_states => {
        _start => sub {
            my ( $kernel, $session, $heap ) = @_[ KERNEL, SESSION, HEAP ];
            $heap->{log2hr} = HTTP::Request::FromLog->new( host => $to_host );
            my $postback = $session->postback("mypostback");
            $kernel->post(
                $tailer->session_id(),
                "start_tail" => {
                    job      => $job,
                    postback => $postback,
                }
            );
            $kernel->delay( "stop_job", 10 );
        },
        mypostback => sub {
            my ( $kernel, $session, $heap, $data ) =
              @_[ KERNEL, SESSION, HEAP, ARG1 ];
            my $log  = $data->[0];
            my $host = $data->[1];
            for ( split( /\n/, $log ) ) {
                my $http_request = $heap->{log2hr}->convert($_);
                $kernel->post( "ua", "request", "response", $http_request );
            }
        },
        stop_job => sub {
            my $kernel = @_[KERNEL];
            $kernel->post( $tailer->session_id(),
                "stop_tail" => { job => $job } );
        },
        response => sub {
            my $req = $_[ARG0]->[0];
            my $res = $_[ARG1]->[0];
            print "-" x 80, "\n";
            print $res->as_string;
        },
    },
);

POE::Kernel->run();

