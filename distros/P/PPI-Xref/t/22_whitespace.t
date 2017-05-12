use Test::More;

use strict;
use warnings;

use PPI::Xref;

use FindBin qw[$Bin];
require "$Bin/util.pl";
my ($xref, $lib) = get_xref({recurse => 0});

local $SIG{__WARN__} = \&warner;

ok($xref->process(\<<__EOF__), "process string");
package # evil
good;
sub # evil
marine {}
use # evil
force;
use # evil
=pod
=head1 evil
=cut
brute;
__EOF__

is_deeply([$xref->packages],
          [
           "good",
          ],
         "package whitespace");

is_deeply([$xref->subs],
          [
           "good::marine",
          ],
         "sub whitespace");

is_deeply([$xref->modules],
          [
           "brute",
           "force",
          ],
         "use whitespace");

done_testing();
