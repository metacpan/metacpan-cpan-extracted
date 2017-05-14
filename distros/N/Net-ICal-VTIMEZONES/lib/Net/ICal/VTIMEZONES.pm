package Net::ICal::VTIMEZONES;

use vars qw($timezones);

BEGIN {
    use Net::ICal::Config;
    my $zonedir = $Net::ICal::Config->{'zoneinfo_location'} || "zoneinfo";

    # I have no idea what the first two fields in this file mean, but
    # the third one is all Olsen timezone names.
    my $zonefile = "$zonedir/zones.tab";

    open(ZONEFILE, $zonefile) 
        or die ("Couldn't open timezone info file $zonefile");

    while (<ZONEFILE>) {
        my @fields = split(' ', $_);
        my $zonename = $fields[2];
        $timezones->{$zonename} = {};
        $timezones->{$zonename}->{'file'} = "$zonedir/$zonename.ics";
    }
}

=head1 NAME

Date::ICal - Perl extension for ICalendar date objects.

=head1 SYNOPSIS

    my $zones = Net::ICal::VTIMEZONES::timezones;

    # a list of all the zones
    @zonenames = keys %{$timezones};

    # to get a file to load VTIMEZONE data from
    $zonefile = $zones->{'America/Bogota'}->{'file'};
    
=head1 METHODS

=head2 timezones

Returns a hashref of hashrefs; the hashref's keys are names of 
timezones. Each timezone hash has one element at present, "file",
which is the file where you can get VTIMEZONE information
for this timezone. 

=cut

sub timezones {
    return $timezones;
}

1;
__END__
