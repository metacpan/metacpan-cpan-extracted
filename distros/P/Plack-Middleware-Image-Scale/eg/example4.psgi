use strict;
use warnings;
use Plack::Builder;
use Config::General;

my $app = sub { return [200,[],[]] };

my %imagesize = Config::General->new('imagesize.conf')->getall;

builder {
    enable 'ConditionalGET';
    enable 'Image::Scale', size => \%imagesize;
    enable 'Static', path => qr{^/images/};
    $app;
};

