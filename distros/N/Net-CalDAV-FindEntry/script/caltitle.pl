#!perl
use 5.020;
use experimental 'signatures';
use experimental 'for_list';

use Getopt::Long;
use YAML::Tiny;
use File::Spec;
use Net::CalDAV::FindEntry;
use Net::CalDAV::Utils;
use File::XDG;

GetOptions(
    'user|u=s'     => \my $user,
    'password|p=s' => \my $password,
    'url=s'        => \my $calendar_url,
    'calendar|c=s' => \my $calendar,
    'config=s'     => \my $config_file,
    'insecure|k'   => \my $no_verify_ssl,

    'mtime=s'      => \my $mtime_file, # maybe we want another tool for that?!
    'guess=s'      => \my $ts_str,
    'unique'       => \my $needs_unique,
    'closest'      => \my $output_closest,
    # Maybe have a switch to simply look at every timestamp given in @ARGV
    # as a single timestamp instead of start-end

    'duration=s'   => \my $duration,
);

# maybe also output title/location/other stuff?
# maybe calquery "time,title,location" ?!

$duration //= 'PT+1H';

# Convert nicer durations to the expected format
if( $duration !~ /^P/ ) {
    $duration =~ s/(\d+)([wdhm])/$1\u$2/g;
    $duration = "PT+$duration";
}

if( $mtime_file ) {
    my @stat = stat( $mtime_file );
    my $ts = ts( $stat[9]);
    my $d_before = $duration =~ s/\+/-/r;
    unshift @ARGV, dtend( $ts, $d_before ), dtend( $ts, $duration );
} elsif( $ts_str ) {
    $ts_str =~ m!(20\d\d)((?:0\d|1[012]))([0123]\d).([012]\d)([0-6]\d)([0-6]\d)!
        or die "Couldn't find timestamp from '$ts_str'";
    my $ts = "$1-$2-$3T$4:$5:$6";
    my $d_before = $duration =~ s/\+/-/r;
    unshift @ARGV, dtend( $ts, $d_before ), dtend( $ts, $duration );
}

my ($before, $after);

if( ! @ARGV ) {
    my $ts = ts( time());
    my $d_before = $duration =~ s/\+/-/r;
    ($after, $before) = (dtend($ts, $d_before), dtend($ts,$duration));
} else {
    ($after, $before) = sort @ARGV;
    $before //= dtend( $after, $duration );
}

my $config = {};
$config_file //= File::XDG->new( name => 'import-images', api => 1 )->lookup_config_file( 'calendar.yml' );
if( $config_file ) {
    $config = YAML::Tiny->read( $config_file )->[0];
}
$calendar //= $config->{calendar};

my $cal = Net::CalDAV::FindEntry->new(
    user         => $user         // $config->{user},
    password     => $password     // $config->{password},
    calendar_url => $calendar_url // $config->{calendar_url},
);
if( $no_verify_ssl ) {
    $cal->ua->verify_SSL(0);
}

$cal->logger(sub($level,@msg) {
   return if ($level eq 'debug' and not $ENV{DEBUG_CALDAV});
   warn "LOG $level: $_\n" for @msg;
});

my @relevant_events = $cal->get_events( after => $after, before => $before, calendar => $calendar );

binmode STDOUT, ':encoding(UTF-8)';
for ( sort { $a->{start} cmp $b->{start} } @relevant_events) {
    say join( "-", $_->{start}, $_->{title} ) ;
}
