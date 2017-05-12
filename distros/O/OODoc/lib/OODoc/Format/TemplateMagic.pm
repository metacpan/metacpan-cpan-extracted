# Copyrights 2003-2015 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.01.

use strict;
use warnings;

package OODoc::Format::TemplateMagic;
use vars '$VERSION';
$VERSION = '2.01';



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

