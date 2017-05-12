use strict;
use Test::More;
use Test::TCP;
use LWP::UserAgent;
use Plack::Builder;
use Plack::Loader;
use File::Temp;

my @servers;
for ( qw/Starman Starlet/ ) {
    if ( eval "require $_; 1" ) {
        push @servers, $_;
    }
}
if ( !@servers ) {
    plan skip_all => 'Starlet or Starman isnot installed';
}
else {
    plan tests => 1 * scalar @servers;
}


for my $server ( @servers ) {
    warn "using $server for test";

    my $dir = File::Temp::tempdir( CLEANUP => 1 );
    my $app = builder {
        enable 'ServerName', name => 'Plack-Middleware-ServerName/0.02';
        sub { sleep 3; [200, [ 'Content-Type' => 'text/plain' ], [ "Hello World" ]] };
    };

    test_tcp(
        client => sub {
            my $port = shift;
            my $pid = fork;
            if ( $pid ) {
                sleep 1;
                my $ua = LWP::UserAgent->new;
                my $res = $ua->get("http://localhost:$port/hello");
                is( $res->header( 'Server' ), 'Plack-Middleware-ServerName/0.02' );
            }
            elsif ( defined $pid ) {
                # slow response
                my $ua = LWP::UserAgent->new;
                my $res = $ua->get("http://localhost:$port/");
                exit;
            }
            waitpid( $pid, 0);
        },
        server => sub {
            my $port = shift;
            my $loader;
            if ( $server eq 'Starman' ) {
                $loader = Plack::Loader->load(
                    $server,
                    host => 'localhost',
                    port => $port,
                    workers => 5,
                );
            }
            elsif ( $server eq 'Starlet' ) {
                $loader = Plack::Loader->load(
                    $server,
                    port => $port,
                    max_workers => 5,
                );
            }
            $loader->run($app);
        },
    );
}
