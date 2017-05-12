#!perl -w

#use Test::More qw(no_plan);
use Test::More tests => 36;

#-----------------------------------------------------------------
# Return a fully qualified name of the given file in the test
# directory "t/data" - if such file really exists. With no arguments,
# it returns the path of the test directory itself.
# -----------------------------------------------------------------
use FindBin qw( $Bin );
use File::Spec;
sub test_file {
    my $file = File::Spec->catfile ('t', 'data', @_);
    return $file if -e $file;
    $file = File::Spec->catfile ($Bin, 'data', @_);
    return $file if -e $file;
    return File::Spec->catfile (@_);
}

# -----------------------------------------------------------------
# Tests start here...
# -----------------------------------------------------------------
ok(1);
use Monitor::Simple;
use Monitor::Simple::Config;
diag( "Testing the configuration" );

# resolving configuration file
{
    my $existing_file = File::Spec->catfile (test_file(), 'c1.empty');
    is (Monitor::Simple::Config->resolve_config_file ($existing_file),
        $existing_file,
        "Resolving file - ad a) failed");
    $ENV{$Monitor::Simple::Config::ENV_CONFIG_DIR} = File::Spec->catfile ($Bin, 'data');
    is (Monitor::Simple::Config->resolve_config_file ('c2.empty'),
        File::Spec->catfile ($Bin, 'data', 'c2.empty'),
        "Resolving file - ad b) failed");
    delete $ENV{$Monitor::Simple::Config::ENV_CONFIG_DIR};
    push (@INC, File::Spec->catfile ($Bin, 'data'));
    is (Monitor::Simple::Config->resolve_config_file ('c3.empty'),
        File::Spec->catfile ($Bin, 'data', 'c3.empty'),
        "Resolving file - ad d) failed");
    pop @INC;
    is (Monitor::Simple::Config->resolve_config_file ('non-existing'),
        undef,
        "Resolving file - ad e) failed");
}

# bad XML
{
    my $bad_xml_file = test_file ('bad.xml');
    eval { Monitor::Simple::Config->get_config ($bad_xml_file) };
    ok ($@, "There should be an error in '$bad_xml_file'");
}

# validating configuration file
{
    my $bad_config_file = test_file ('bad-config.xml');
    eval { my $config = Monitor::Simple::Config->get_config ($bad_config_file) };
    my $errors = $@;
    ok ($errors, "There should be errors in '$bad_config_file'");
    my @error_msgs = (
        "Service number 1 does not have an ID attribute",
        "Service number 1 does not have any plugin section",
        "Service 'Letter A' has a plugin without any 'command' attribute",
        "Notifier number 1 in service 'Letter A' has no 'command' attribute",
        "Service 'Letter B' has more than one plugin tag",
        "General notifier number 1 has no 'command' attribute",
        );
    foreach my $msg (@error_msgs) {
        my $qmsg = "\Q$msg";
        ok ($errors =~ m{$qmsg}, "Missing error: $msg");
    }
}

# general section of a configuration file
my $filename = 'config.xml';
my $config_file = test_file ($filename);
my $config = Monitor::Simple::Config->get_config ($config_file);
ok ($config, "Failed configuration taken from '$config_file'");
is (ref ($config->{services}),
    'ARRAY',
    "Services should be an arrayref");
is (ref ($config->{general}->{'email-group'}),
    'ARRAY',
    "email-group should be an arrayref");
is (ref ($config->{general}->{'email-group'}->[0]->{email}),
    'ARRAY',
    "email-group/email should be an arrayref");
is (ref ($config->{general}->{notifier}),
    'ARRAY',
    "notifier should be an arrayref");
is (ref ($config->{general}->{notifier}->[0]->{args}),
    'ARRAY',
    "notifier/args should be an arrayref");

# setting default values
my $plugindir = File::Spec->catdir(qw(Monitor Simple plugins));
$plugindir =~ s/\\/\\\\/g;
ok ($config->{general}->{'plugins-dir'} =~ m{$plugindir$},
    "Bad default value for plugins directory: $config->{general}->{'plugins-dir'}");
my $notifiersdir = File::Spec->catdir(qw(Monitor Simple notifiers));
$notifiersdir =~ s/\\/\\\\/g;
ok ($config->{general}->{'notifiers-dir'} =~ m{$notifiersdir$},
    "Bad default value for notifiers directory: $config->{general}->{'notifiers-dir'}");
{
    my $service_id = 'no-name-service';
    my $service = Monitor::Simple::Config->extract_service_config ($service_id, $config);
    ok ($service, "Missing service configuration for service '$service_id'");
    is ($service->{name},
        $service_id,
        "Bad default value for service name");
}

# section with an individual service
{
    my $service_id = 'XXX.no-name-service';
    my $savewarn = $SIG{'__WARN__'};
    $SIG{'__WARN__'} = sub {};
    my $service = Monitor::Simple::Config->extract_service_config ($service_id, $config);
    is ($service, undef, "Should return undef for service '$service_id'");
    $SIG{'__WARN__'} = $savewarn;
}
{
    my $service_id = 's1';
    my $service = Monitor::Simple::Config->extract_service_config ($service_id, $config);
    ok ($service, "Configuration for service '$service_id'");
}
{
    my $service_id = 'copy';
    my $service = Monitor::Simple::Config->extract_service_config ($service_id, $config);
    ok ($service, "Configuration for service '$service_id'");
    is ($service->{name},
        '<Moderated> "exit"',
        "Service name with unusual chars");
}
{
    my $service_id = 's1';
    my $service = Monitor::Simple::Config->extract_service_config ($service_id, $config);
    ok ($service, "Configuration for service '$service_id'");
    is (ref ($service->{plugin}->{'head-test'}),
        'ARRAY',
        "head-test should be an arrayref");
    is (ref ($service->{plugin}->{'get-test'}),
        'ARRAY',
        "get-test should be an arrayref");
    is (ref ($service->{plugin}->{'post-test'}),
        'ARRAY',
        "post-test should be an arrayref");
    is (ref ($service->{plugin}->{'get-test'}->[0]->{response}->{contains}),
        'ARRAY',
        "response/contains should be an arrayref");
}

# creation of the arguments for plugins
{
    my $savewarn = $SIG{'__WARN__'};
    $SIG{'__WARN__'} = sub {};
    my @args = Monitor::Simple::Config->create_plugin_args ('config.file', $config, 'unknown-service');
    is (scalar @args, 0, "No arguments for unknown service");
    $SIG{'__WARN__'} = $savewarn;
}
{
    my @args = Monitor::Simple::Config->create_plugin_args ('config.file', $config, 's1');
    is (scalar @args, 4, "Number of arguments for a standard plugin");
    is_deeply (\@args,
               [qw(-cfg config.file -service s1)],
               "Create standard plugin arguments");
}
{
    my @args = Monitor::Simple::Config->create_plugin_args ('whatever', $config, 'copy');
    is_deeply (\@args,
               ['2', 'This is an <"artificial"> error'],
               "Create user-defined plugin arguments");
}


__END__
