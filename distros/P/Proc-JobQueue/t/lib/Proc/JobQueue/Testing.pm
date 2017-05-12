
package Proc::JobQueue::Testing;

use strict;
use warnings;
use FindBin qw($Bin);

$Proc::JobQueue::host_canonicalizer = 'Proc::JobQueue::FakeCanonical';
$Proc::JobQueue::debug = $::debug;

1;
