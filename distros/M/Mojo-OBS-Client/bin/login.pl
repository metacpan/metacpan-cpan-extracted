#!perl
use 5.012;
use strict;
use warnings;
use Filter::signatures;
use feature 'signatures';
no warnings 'experimental::signatures';

use Getopt::Long;
use Pod::Usage;

use Mojo::OBS::Client;

GetOptions(
    'u=s' => \my $url,
    'p=s' => \my $password,
) or pod2usage(2);

$url //= 'ws://localhost:4444';

my $h = Mojo::OBS::Client->new(
    #debug => 1
);

my $r = $h->login( $url, $password )
->then(sub($res) {
    if( $res->{error}) {
        die $res->{error}
    } else {
        say "Logged into $url";
        $h->SetTextFreetype2Properties( source => 'Text.NextTalk',text => 'Hello World')
    };
})->then(sub(@) {
    $h->GetSourceSettings( sourceName => 'VLC.Vortrag', sourceType => 'vlc_source')
})->then(sub(@) {
    # Queue up a talk
    $h->SetSourceSettings( sourceName => 'VLC.Vortrag', sourceType => 'vlc_source',
    sourceSettings => {
                                'playlist' => [
                                                {
                                                  'value' => '/home/gpw/gpw2021-recordings/2021-02-02 18-21-42.mp4',
                                                  'hidden' => $JSON::false,
                                                  'selected' => $JSON::false,
                                                }
                                              ]
                                          },
    );

    say "Stopping loop";
    Mojo::IOLoop->stop_gracefully;
    return Future->done;

})->catch(sub {
    warn $_[0];
    Mojo::IOLoop->stop_gracefully;
});

Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
