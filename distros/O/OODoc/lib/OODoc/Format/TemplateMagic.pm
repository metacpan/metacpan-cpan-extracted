# Copyrights 2003-2021 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of perl distribution OODoc.  It is licensed under the
# same terms as Perl itself: https://spdx.org/licenses/Artistic-2.0.html

use strict;
use warnings;

package OODoc::Format::TemplateMagic;
use vars '$VERSION';
$VERSION = '2.02';



sub zoneGetParameters($)
{   my ($self, $zone) = @_;
    my $param = ref $zone ? $zone->attributes : $zone;
    $param =~ s/^\s+//;
    $param =~ s/\s+$//;

    return () unless length $param;

    return split / /, $param       # old style
       unless $param =~ m/[^\s\w]/;

    # new style
    my @params = split /\s*\,\s*/, $param;
    map { (split /\s*\=\>\s*/, $_, 2) } @params;
}

1;

