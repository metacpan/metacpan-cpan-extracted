use Test::Simple tests => 1;
my($destroy, $put);
use Carp qw(confess);
$SIG{__DIE__} = \&confess;

use URI;
use POE::Component::FastCGI::Response;
use POE::Filter::FastCGI;
# loaded
ok(1);

