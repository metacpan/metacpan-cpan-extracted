use strict;
use warnings;
use Plack::Builder;

my $app = sub { return [200,[],[]] };

builder {
    enable 'ConditionalGET';
    enable 'Image::Scale';
    enable 'Static', path => qr{^/images/};
    $app;
};

