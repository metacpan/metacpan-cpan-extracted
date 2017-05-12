use Mojo::Base -strict;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/../lib";

BEGIN {
    use_ok 'DateTime';
    use_ok 'Mojolicious::Plugin::DateTime';
}

done_testing;
