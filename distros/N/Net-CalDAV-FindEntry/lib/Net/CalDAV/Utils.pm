package Net::CalDAV::Utils 0.01;
use 5.020;
use experimental 'signatures';
use Exporter 'import';
use POSIX 'strftime';
use Time::Local;

our @EXPORT = (qw(ts tslocal dtend));

sub ts( $time ) {
    return strftime '%Y-%m-%dT%H:%M:%S', localtime( $time )
}

sub dtend( $ts, $duration ) {
    # convert $ts to unix timestamp
    my @parts = reverse split /\D/, $ts;
    $parts[4]--; # month is zero-based ...
    my $time = timelocal( @parts );

    # convert $duration to seconds
    $duration =~ s/^PT?//
        or die "Can't parse a duration from '$duration'";
    my @units = ($duration =~ /([+-]?\d+)([DHMS])/g);
    for my( $d, $unit ) (@units) {
        # Yeah, this doesn't play nice with DST changes
        $time += $d * { H => 60*60, M => 60, S => 1, D => 24*60*60, W => 7*24*60*60 }->{$unit};
    }
    return ts( $time )
}

sub tslocal( $ts ) {
    my @parts = reverse split /\D/, $ts;
    $parts[4]--; # month is zero-based ...
    ts( timegm( @parts ));
}


1;
