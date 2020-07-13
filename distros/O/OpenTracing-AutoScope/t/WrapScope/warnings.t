use Test::Most tests => 3;
use OpenTracing::WrapScope;

use constant ERROR_MSG => qr/Couldn't find sub/;

warning_like {
    OpenTracing::WrapScope::install_wrapped('main::foo');
} ERROR_MSG, 'warning shown on attempt to install an unkown sub';

ok !defined &main::foo, 'no side effects of a failed installation';

throws_ok {
    use warnings FATAL => 'OpenTracing::WrapScope';
    OpenTracing::WrapScope::install_wrapped('main::bar');
} ERROR_MSG, 'unkown sub dies with FATAL warnings on';
