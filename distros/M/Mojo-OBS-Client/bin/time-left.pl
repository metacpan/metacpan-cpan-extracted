#!perl
use strict;
use warnings;
use 5.020;
use Filter::signatures;
use feature 'signatures';
no warnings 'experimental::signatures';

use Getopt::Long;
use Pod::Usage;
use POSIX 'strftime';

use Mojo::OBS::Client;

GetOptions(
    'u=s' => \my $url,
    'p=s' => \my $password,
) or pod2usage(2);

$url //= 'ws://localhost:4444';

my ($source_name) = @ARGV;

$source_name //= 'VLC.Vortrag';

my $h = Mojo::OBS::Client->new;
my $r = $h->login($url => $password);

my $l = $h->add_listener('StreamStatus' => sub( $status ) {
    say sprintf "Status: '%s'", $status->{"update-type"};
});

Mojo::IOLoop->recurring(1 => sub {
    my $scene;
    my $duration;
    $h->GetCurrentScene()->then(sub($reply) {
        $scene = $reply->{"name"};
        Future->done();
    })->then(sub {
        $h->GetMediaDuration($source_name)
    })->then(sub( $reply) {
        $duration = $reply->{mediaDuration};
        Future->done();
    })->then(sub() {
        $h->GetMediaTime($source_name)
    })->then(sub($reply) {

        my $timestamp = $reply->{timestamp};
        my $ts = $timestamp / 1000;

        my $left = ($duration - $timestamp)/1000;

        my $total     = strftime "%H:%M:%S", gmtime ($duration / 1000);
        my $running   = strftime "%H:%M:%S", gmtime $ts;
        my $remaining = strftime ' %H:%M:%S', gmtime $left;

        $| = 1;
        print join "\t", $source_name, $running, $remaining, $total;
        print "\r";

        Future->done();
    })->retain;
});

Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

