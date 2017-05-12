#!perl -Tw

use Test::More;
use Solaris::SMF;

# There's no point trying to test on anything but Solaris 9 or above.
$ENV{PATH} = '/bin:/usr/bin:/sbin:/usr/sbin';
my ( $OS, $release ) = split( / /, `uname -sr` );
plan skip_all => 'No point testing on non-Solaris operating system.'
    unless $OS eq 'SunOS';
plan skip_all => 'Solaris 9, 10 or above is required.'
    unless $release =~ m/ 5\.(?:9|1[0-9]) /xms;

my $author_tests = $ENV{RELEASE_TESTING} ? 1 : 0;

# Check we can get all and no services
ok( defined get_services(), 'get_services *' );
my @nonexistent_services = get_services( wildcard => 'Nonexistent' );
ok( scalar @nonexistent_services == 0, 'get_services Nonexistent' );

# Check that a well-known service milestone is found
my @service = get_services( wildcard => 'multi-user-server' );
ok( scalar @service == 1,
    'get_services multi-user-server returned ' . scalar @service );

my @services = get_services();
my ( $legacy_done, $standard_done ) = ( 0, 0 );
SERVICE:
for my $service (@services) {

    my $FMRI   = $service->FMRI();
    my $status = $service->status();

    # Check attributes of this service
    ok( $FMRI =~ m/(?:svc|lrc):/xms,
        "'$FMRI' does not match the pattern for FMRI" );
    ok( $status
            =~ m/online|offline|enabled|disabled|inactive|maintenance|legacy_run/xms,
        "'$FMRI' has unknown status '$status'"
    );

    my ( $properties, $enabled_property, $enabled_proptype );
    if ( $FMRI !~ m/lrc/xms ) {
        next SERVICE if ( !$author_tests && $standard_done );
        $author_tests && warn "Testing standard service '$FMRI'";
        local $SIG{__WARN__} = sub { die $_[0] };
        local $@;
        eval {
            $properties       = $service->properties();
            $enabled_property = $service->property('general/enabled');
            $enabled_proptype = $service->property_type('general/enabled');
        };
        my $props_warnings = $@;

        # Get the properties of this service
        ok( $props_warnings eq '',
            "Warnings produced when checking standard service '$FMRI' properties"
        );
        ok( defined($properties), "'$FMRI' properties are not defined" );
        ok( $enabled_property eq ( $status eq 'enabled' ) ? 'true' : 'false',
            "'$FMRI' enabled property is '$enabled_property', not $status"
        );
        ok( $enabled_proptype eq 'boolean',
            "'$FMRI' enabled property type is '$enabled_proptype', not
            boolean!"
        );
        $standard_done = 1;
    }
    else {
        next SERVICE if ( !$author_tests && $legacy_done );
        $author_tests && warn "Testing legacy service '$FMRI'";
        local $SIG{__WARN__} = sub { die $_[0] };
        local $@;
        eval {
            $properties       = $service->properties();
            $enabled_property = $service->property('general/enabled');
            $enabled_proptype = $service->property_type('general/enabled');
        };
        my $props_warnings = $@;

        ok( $props_warnings ne '',
            "No warnings produced when checking legacy '$FMRI' properties" );
        ok( defined($properties), "Legacy '$FMRI' properties are defined" );
        ok( !defined($enabled_property),
            "Legacy '$FMRI' enabled property is not undefined" );
        ok( !defined $enabled_proptype,
            "Legacy '$FMRI' enabled property type is not undefined" );
        $legacy_done = 1;
    }
}

done_testing();

