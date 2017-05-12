use strict;
use warnings;
use File::Spec;
use File::Basename 'dirname';
use lib (
    File::Spec->catdir(dirname(__FILE__), 'lib'), 
);
use Plack::Builder;
use NephiaX::Auth::Twitter;

NephiaX::Auth::Twitter->run(
    consumer_key    => 'YOUR_CONSUMER_KEY',
    consumer_secret => 'YOUR_CONSUMER_SECRET',
    handler => sub {
        my ($c, $twitter_id) = @_;
        [200, [], ['Hello, '.$twitter_id]];
    },
);

