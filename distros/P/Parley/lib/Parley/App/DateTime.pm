package Parley::App::DateTime;
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

use Parley::Version;  our $VERSION = $Parley::VERSION;

use DateTime;
use Perl6::Export::Attrs;

sub interval_ago_string :Export( :interval ) {
    my ($datetime) = @_;
    my ($now, $duration, $longest_duration);

    # get now as a DT object
    $now = DateTime->now();

    # the difference between now and the post time
    $duration = $now - $datetime;

    # we use the largest unit to give an idea of how long ago the post was made
    foreach my $unit (qw[years months days hours minutes seconds]) {
        if ($longest_duration = $duration->in_units($unit)) {
            return _time_string($longest_duration, $unit);
        }
    };

    # we should get *something* in the loop above, but just in case
    return '0 seconds';
}


sub _time_string {
    my ($duration, $unit) = @_;

    # DateTime::Duration uses plural names for units
    # so if we have ONE we need to return the singular
    if (1 == $duration) {
        $unit =~ s{s\z}{};
    }

    # localise the unit
    #$unit = $c->localize($unit);

    return "$duration $unit";
}
1;
