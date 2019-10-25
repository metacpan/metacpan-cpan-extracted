use strict;
use warnings;
use Test::More;

use lib qw(lib ../lib);

BEGIN { use_ok 'QMail::QueueHandler'; }

# Running new() randomly like this will splurge the help text to
# STDOUT. Let's stop that from appearing in the test output.
close STDOUT;
open STDOUT, '>', \(my $output);

my $qh;
eval { ok($qh = QMail::QueueHandler->new, 'Got something') };

isa_ok($qh, 'QMail::QueueHandler');

ok($output, 'Got some help text');

for my $c (qw(run commands restart to_delete to_flag msglist colours)) {
  can_ok($qh, $c);
}

my $stopped;
eval { $stopped = $qh->stop_qmail; };
ok( !$stopped , 'Stops qmail');
done_testing();
