use strict;
use warnings;
use Plack::Builder;

my $app = sub { return [200,[],[]] };

my $imagesize = {
    small   => [ 40,100],
    medium  => [140,200],
    big     => [240,300],
};

builder {
    enable 'ConditionalGET';
    enable 'Image::Scale', size => $imagesize;
    enable 'Static', path => qr{^/images/};
    $app;
};

