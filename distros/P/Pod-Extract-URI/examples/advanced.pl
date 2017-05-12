use strict;
use warnings;
use Pod::Extract::URI;
use Pod::Find qw( pod_where );

# This script demonstrates some more advanced features of
# Pod::Extract::URI, by extracting the URIs from a module's
# documentation (URI::Find, by default).

# Find the POD to process
my $module = shift @ARGV || 'URI::Find';
my $filename = pod_where( { -inc => 1 }, $module );
exit 1 unless $filename;

# We use a "stop_sub" to check each URI to see if we want it
# or not - it's a bit more powerful than the stop_uris regexp
# approach
my $peu = Pod::Extract::URI->new(
    stop_sub => \&stop,
);

# Get the URIs and a hash of details
$peu->uris_from_file( $filename );
my %details = $peu->uri_details;

# And output a pretty(ish) report
print "URIs found:\n";
for my $uri ( keys %details ) {
    print "  $uri:\n";
    for ( @{ $details{ $uri } } ) {
        print "    Line " . $_->{ line } . " (as " . $_->{ original_text } . ")\n";
    }
}

# URI::Find includes the text 'http://' and 'ftp://' which
# get picked up as URIs, so we use the stop_sub to only
# give us URIs that have a host.

sub stop {
    my $uri = shift;
    if ( $uri->can( 'host' ) && ! $uri->host ) {
        return 1;
    } else {
        return 0;
    }
}

