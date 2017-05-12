use strict;
use warnings;
use autodie qw(fork);

use File::Temp;
use Plack::Builder;
use Plack::Loader;
use Plack::VCR;
use Test::Exception;
use Test::More tests => 1;
use Test::TCP;

my $tempfile = File::Temp->new;
close $tempfile;

my $server = Test::TCP->new(
    code => sub {
        my ( $port ) = @_;

        my $app = builder {
            enable 'Recorder', output => $tempfile->filename;
            sub {
                return [
                    200,
                    ['Content-Type' => 'text/plain'],
                    ['OK'],
                ];
            };
        };

        Plack::Loader->auto(port => $port, host => '127.0.0.1')->run($app);
    },
);

my $pid = fork;

if($pid) {
    waitpid $pid, 0;
} else {
    require LWP::UserAgent;

    my $ua = LWP::UserAgent->new;
    $ua->request(HTTP::Request->new('GET' =>
        'http://localhost:' . $server->port . '/'));
    exit 0;
}

undef $server;

my $vcr         = Plack::VCR->new(filename => $tempfile->filename);
my $interaction = $vcr->next;
my $request     = $interaction->request;
lives_ok {
    $request->method;
};
