use strict;
use warnings;
use POE;
use POE::Component::RemoteTail;
use lib qw( t/lib );
use Test::More tests => 1;

my ( $i, $j ) = ( 0, 0 );

my $alias = "tailer";

my $tailer = POE::Component::RemoteTail->spawn( alias => $alias );

my $job = $tailer->job(
    host          => "test01",
    path          => "/home/httpd/test01/logs/access_log.20080708",
    user          => "hoge",
    password      => "fuga",
    process_class => "MyTestEngine",
);

POE::Session->create(
    inline_states => {
        _start => sub {
            my ( $kernel, $session ) = @_[ KERNEL, SESSION ];
            my $postback = $session->postback("mypostback");
            $kernel->post(
                $alias,
                "start_tail" => {
                    job      => $job,
                    postback => $postback
                }
            );
            $kernel->delay_add( "stop_job", 3, $job );
        },
        mypostback => sub {
            my ( $kernel, $session, $data ) = @_[ KERNEL, SESSION, ARG1 ];
            my $host = $data->[1];
            my $log  = $data->[0];
            for ( split( /\n/, $log ) ) {
                check($_);
                #print $host, "\t", $_, "\n";
            }
        },
        stop_job => sub {
            my ( $kernel, $job ) = @_[ KERNEL, ARG0 ];
            $kernel->post( $alias, "stop_tail" => {job => $job} );
            is( $j, 1000, "loop OK" );
            $kernel->stop();
        },
    },
);

POE::Kernel->run();

sub check {
    my $log = shift;
    $log =~ s/logloglog_//;

    if ( $log == ++$i ) {
        $j++;
    }
}

