use strict;
use warnings;

# try this out with:
#   plackup examples/synopsis.psgi &
#   curl http://localhost:5000/hi

use Log::Dispatch;
use Plack::Builder;

my $logger = Log::Dispatch->new(
    outputs => [
        [ File => filename => 'example.log', min_level => 'debug' ],
    ],
);

my $app = sub {
    my $env = shift;

    # this will go to our configured logger
    # and conveniently enough, so does the access log!
    $env->{'psgi.errors'}->print("oh noes!\n");

    [ 200, [], [ 'hello' ] ];
};

builder {
    enable 'LogDispatch', logger => $logger;
    enable 'LogErrors';
    $app;
}

