use Test::More tests => 4;

use strict;
use warnings;

use_ok( 'Template' );
use_ok( 'Template::Provider::FromDATA' );

{ # NO PRELOAD
    my $provider = Template::Provider::FromDATA->new;
    is_deeply( { classes => {}, templates => {} }, $provider->cache, 'no PRELOAD' );
}

{ # WITH PRELOAD
    my $provider = Template::Provider::FromDATA->new( { PRELOAD => 1 } );
    is_deeply( {
        classes => { main => 1 }, templates => { 'main/foo' => "bar\n" }
    }, $provider->cache, 'with PRELOAD' );
}


__DATA__

__foo__
bar
