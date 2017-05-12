package Moonshine::Bootstrap::v3;

use strict;
use warnings;

use Moonshine::Magic;
use Moonshine::Util;
use Module::Find;

extends (
    'Moonshine::Bootstrap::Component', 
);

BEGIN {
    with (
        ( map {
            $_
        } findsubmod 'Moonshine::Bootstrap::v3' )
    );
}

1;

__END__


