use strict;
use warnings;

use File::Spec;
use File::Basename qw(dirname);
use Plack::Middleware::DevFavicon;
use Plack::Builder;


builder {
    enable_if { $ENV{PLACK_ENV} eq 'development' } 'DevFavicon';
    enable 'Static',
        path => qr{/favicon\.(?:ico|png)$},
        root => File::Spec->catfile(dirname(__FILE__), '../t/assets'),
    ;

    return sub {
        [200, ['Content-Type' => 'text/plain'], ['Hello, world!']];
    };
};

