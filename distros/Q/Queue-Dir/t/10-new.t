use File::Path;
use Queue::Dir;
use Test::More tests => 3;

END { rmtree (["test$$"]); }

mkdir "test$$";

my $q = new Queue::Dir paths => [ '.' ];

ok(defined $q, 'Proper ->new()');

$q = new Queue::Dir paths => [ "test$$" ];

ok(defined $q, 'Proper ->new() with a path');

$q = undef;

eval { $q = new Queue::Dir paths => [ "not$$" ] };

ok(! defined $q, '->new() with unexistant path');

