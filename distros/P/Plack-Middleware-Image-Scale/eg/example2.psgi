use strict;
use warnings;
use Plack::Builder;
use Plack::App::File;

my $thumber = builder {
    enable 'ConditionalGET';
    enable 'Image::Scale',
        width => 200, height => 100,
        flags => { fill => 'ff00ff' };
    Plack::App::File->new( root => 'images' );
};

my $app = sub { return [200,['Content-Type'=>'text/plain'],['hello']] };

builder {
    mount '/thumbs' => $thumber;
    mount '/' => $app;
};

