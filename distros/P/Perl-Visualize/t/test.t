# test.t -- 
# Author          : Jasvir Nagra <jas@cs.arizona.edu>
# Created On      : Tue Jun 17 04:06:20 2003
# Last Modified   : <03/07/02 09:11:57 jas>
# Description     : Tests the Perl::Visualize module
# Keywords        : perl visualize piet larry source
# PURPOSE
# 	| Test Perl::Visualize |

use Test::More tests => 4;
BEGIN { use_ok('Perl::Visualize') };

is(`$^X t/1.gif`, "", "no op");
is(`$^X t/2.gif`, "ok 2\n", "etch");
is(`$^X t/3.gif`, "ok 3\n", "paint");


# Emacs bunkum
# Local Variables:
# mode: fundamental
# time-stamp-start: "Last Modified[ \t]*:[ 	]+\\\\?[\"<]+"
# time-stamp-end:   "\\\\?[\">]"
# End:
