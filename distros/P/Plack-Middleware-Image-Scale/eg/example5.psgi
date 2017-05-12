use strict;
use warnings;
use Plack::Builder;

my $app = sub { return [200,[],[]] };

builder {
    enable 'ConditionalGET';
    enable 'Image::Scale', orig_ext => [qw( jpg png pdf )];
    enable 'Static', path => qr{^/images/};
    $app;
};

