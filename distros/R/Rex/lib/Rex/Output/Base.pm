#
# (c) Nathan Abu <aloha2004@gmail.com>
#

package Rex::Output::Base;

use v5.14.4;
use warnings;

our $VERSION = '1.16.1'; # VERSION

sub write { die "Must be implemented by inheriting class" }
sub add   { die "Must be implemented by inheriting class" }
sub error { die "Must be implemented by inheriting class" }

1;
