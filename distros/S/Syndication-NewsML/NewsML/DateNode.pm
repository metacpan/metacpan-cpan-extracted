# $Id: DateNode.pm,v 0.1 2002/02/13 14:11:43 brendan Exp brendan $
# Syndication::NewsML::DateNode.pm

$VERSION     = sprintf("%d.%02d", q$Revision: 0.1 $ =~ /(\d+)\.(\d+)/);
$VERSION_DATE= sprintf("%s", q$Date: 2002/02/13 14:11:43 $ =~ m# (.*) $# );

$DEBUG = 1;

# Syndication::NewsML::DateNode -- superclass defining an extra method for elements
#                             that contain ISO8601 formatted dates
#
package Syndication::NewsML::DateNode;

# convert ISO8601 date/time into Perl internal date/time.
# always returns perl internal date, in UTC timezone.
sub getDatePerl {
    my ($self, $timezone) = @_;
    use Time::Local;
    my $dateISO8601 = $self->getText;
    my ($yyyy, $mm, $dd, $hh, $mi, $ss, $tzsign, $tzhh, $tzmi) = ($dateISO8601 =~ qr/(\d\d\d\d)(\d\d)(\d\d)T?(\d\d)?(\d\d)?(\d\d)?([+-])?(\d\d)?(\d\d)?/);
    my $perltime = timegm($ss, $mi, $hh, $dd, $mm-1, $yyyy);
    if ($tzhh) {
        my $deltasecs = 60 * ($tzsign eq "-") ? -1*($tzhh * 60 + $tzmi) : ($tzhh * 60 + $tzmi);
        $perltime += $deltasecs;
    }
    return $perltime;
}

1;
