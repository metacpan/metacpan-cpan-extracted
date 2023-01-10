use Test::Most tests => 1;

use Mojo::UserAgent;
use Mojo::Util qw/dumper/;

$\ = "\n";
$, = "\t";

BEGIN {
    my $stderr = '';
    local *STDERR;
    open STDERR, '>', \$stderr;

    require Role::Tiny::MonkeyPatch;
    Role::Tiny::MonkeyPatch->import( qw/Mojo::UserAgent/ );
    ok($stderr =~ /already has roles/)
}
