package Promise::XS::Loader;

use strict;
use warnings;

our $VERSION = '0.10';

require XSLoader;
XSLoader::load('Promise::XS', $VERSION);

sub _convert_to_our_promise {
    my $thenable = shift;
    my $deferred= Promise::XS::Deferred::create();
    my $called;

    local $@;
    eval {
        $thenable->then(sub {
            return if $called++;
            $deferred->resolve(@_);
        }, sub {
            return if $called++;
            $deferred->reject(@_);
        });
        1;
    } or do {
        my $error= $@;
        if (!$called++) {
            $deferred->reject($error);
        }
    };

    # This promise is purely internal, so let’s not warn
    # when its rejection is unhandled.
    $deferred->clear_unhandled_rejection();

    return $deferred->promise;
}

Promise::XS::Deferred::___set_conversion_helper(
    \&_convert_to_our_promise,
);

1;
