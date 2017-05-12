use Mojo::Base qw{ -strict };
use File::Basename;
use File::Spec;

my $dir = dirname(__FILE__);
require File::Spec->catfile( $dir, 'util.pl' );

use Mojo::IOLoop;
use Mojo::UserAgent;
use Test::More tests => 3;
use File::Temp;

my $message   = "Hello World";
my $app       = File::Spec->catfile( $dir, '..', 'bin', 'mwtail' );
my $webtailrc = File::Spec->catfile( $dir, 'app', 'webtailrc' );

subtest 'file' => sub {
    my $file = File::Temp->new;
    $file->autoflush; # enable autoflush

    my $url = start_server( $app, options => [ '--file' => $file->filename, '--verbose' ] );
    $url->scheme('ws')->path('/webtail');

    my $got;
    my $ua = Mojo::UserAgent->new;
    $ua->websocket( $url => sub {
        my ($ua, $tx) = @_;
        $tx->on( message => sub { $got = $_[1]; Mojo::IOLoop->stop } );
        sleep 3;
        $file->print("$message\n");
    });
    Mojo::IOLoop->start;

    chomp $got;
    is $got, $message;

    stop_server();
};

subtest 'stdin' => sub {
    my ( $url, $pid ) = start_server($app);
    $url->scheme('ws')->path('/webtail');

    my $got;
    my $ua = Mojo::UserAgent->new;
    $ua->websocket( $url => sub {
        my ($ua, $tx) = @_;
        $tx->on( message => sub { $got = $_[1]; Mojo::IOLoop->stop } );
        my $fh = get_server($pid)->{fh};
        print $fh "$message\n";
    });
    Mojo::IOLoop->start;

    chomp $got;
    is $got, $message;

    stop_server();
};

subtest 'webtailrc' => sub {
    my $url = start_server($app, options => [ '--webtailrc' => $webtailrc ] );
    $url->path('/webtail');

    my $ua = Mojo::UserAgent->new;
    like $ua->get($url)->res->body, qr/console\.log\('Hello World'\)/m;

    stop_server();
};

done_testing;
