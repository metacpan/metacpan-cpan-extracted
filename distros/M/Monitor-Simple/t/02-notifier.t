#!perl -w

#use Test::More qw(no_plan);
use Test::More tests => 45;

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

#-----------------------------------------------------------------
# Return a configuration extracted from the given file.
# -----------------------------------------------------------------
sub get_config {
    my $filename = shift;
    my $config_file = test_file ($filename);
    my $config = Monitor::Simple::Config->get_config ($config_file);
    ok ($config, "Failed configuration taken from '$config_file'");
    return $config;
}

# -----------------------------------------------------------------
# Tests start here...
# -----------------------------------------------------------------
ok(1);
use Monitor::Simple;
use Monitor::Simple::Notifier;
diag( "Testing notifiers" );

# instantiate a notifier
{
    my $notifier = Monitor::Simple::Notifier->new (a => 1, b => 2, c => 3);
    is ($notifier->{a}, 1, "Init arguments for a notifier (a)");
    is ($notifier->{b}, 2, "Init arguments for a notifier (b)");
    is ($notifier->{c}, 3, "Init arguments for a notifier (c)");
}

# matching codes
{
    my $notifier = Monitor::Simple::Notifier->new();
    my $c_and_u = Monitor::Simple::NOTIFY_CRITICAL . ',' . Monitor::Simple::NOTIFY_UNKNOWN;

    my @combos = (
        # [0]code_from_config (string)     [1]code_from_result (number)      [2]matches
        # -----------------------------    -----------------------------     ----------
        [Monitor::Simple::NOTIFY_OK,       Monitor::Simple::RETURN_OK,       1],
        [Monitor::Simple::NOTIFY_OK,       Monitor::Simple::RETURN_WARNING,  0],
        [Monitor::Simple::NOTIFY_OK,       Monitor::Simple::RETURN_CRITICAL, 0],
        [Monitor::Simple::NOTIFY_OK,       Monitor::Simple::RETURN_UNKNOWN,  0],

        [Monitor::Simple::NOTIFY_WARNING,  Monitor::Simple::RETURN_OK,       0],
        [Monitor::Simple::NOTIFY_WARNING,  Monitor::Simple::RETURN_WARNING,  1],
        [Monitor::Simple::NOTIFY_WARNING,  Monitor::Simple::RETURN_CRITICAL, 0],
        [Monitor::Simple::NOTIFY_WARNING,  Monitor::Simple::RETURN_UNKNOWN,  0],

        [Monitor::Simple::NOTIFY_CRITICAL, Monitor::Simple::RETURN_OK,       0],
        [Monitor::Simple::NOTIFY_CRITICAL, Monitor::Simple::RETURN_WARNING,  0],
        [Monitor::Simple::NOTIFY_CRITICAL, Monitor::Simple::RETURN_CRITICAL, 1],
        [Monitor::Simple::NOTIFY_CRITICAL, Monitor::Simple::RETURN_UNKNOWN,  0],

        [Monitor::Simple::NOTIFY_UNKNOWN,  Monitor::Simple::RETURN_OK,       0],
        [Monitor::Simple::NOTIFY_UNKNOWN,  Monitor::Simple::RETURN_WARNING,  0],
        [Monitor::Simple::NOTIFY_UNKNOWN,  Monitor::Simple::RETURN_CRITICAL, 0],
        [Monitor::Simple::NOTIFY_UNKNOWN,  Monitor::Simple::RETURN_UNKNOWN,  1],

        [Monitor::Simple::NOTIFY_ALL,      Monitor::Simple::RETURN_OK,       1],
        [Monitor::Simple::NOTIFY_ALL,      Monitor::Simple::RETURN_WARNING,  1],
        [Monitor::Simple::NOTIFY_ALL,      Monitor::Simple::RETURN_CRITICAL, 1],
        [Monitor::Simple::NOTIFY_ALL,      Monitor::Simple::RETURN_UNKNOWN,  1],

        [Monitor::Simple::NOTIFY_ERRORS,   Monitor::Simple::RETURN_OK,       0],
        [Monitor::Simple::NOTIFY_ERRORS,   Monitor::Simple::RETURN_WARNING,  1],
        [Monitor::Simple::NOTIFY_ERRORS,   Monitor::Simple::RETURN_CRITICAL, 1],
        [Monitor::Simple::NOTIFY_ERRORS,   Monitor::Simple::RETURN_UNKNOWN,  1],

        [Monitor::Simple::NOTIFY_NONE,     Monitor::Simple::RETURN_OK,       0],
        [Monitor::Simple::NOTIFY_NONE,     Monitor::Simple::RETURN_WARNING,  0],
        [Monitor::Simple::NOTIFY_NONE,     Monitor::Simple::RETURN_CRITICAL, 0],
        [Monitor::Simple::NOTIFY_NONE,     Monitor::Simple::RETURN_UNKNOWN,  0],

        [$c_and_u,                         Monitor::Simple::RETURN_OK,       0],
        [$c_and_u,                         Monitor::Simple::RETURN_WARNING,  0],
        [$c_and_u,                         Monitor::Simple::RETURN_CRITICAL, 1],
        [$c_and_u,                         Monitor::Simple::RETURN_UNKNOWN,  1],
        );
    my $count = 0;
    foreach my $combo (@combos) {
        $count++;
        is ($notifier->matching_code ($combo->[1], $combo->[0]),
            $combo->[2],
            "Matching codes ($count): Result = " . $combo->[1] . ", Config = " . $combo->[0]);
    }
}

my $config = get_config ('notifiers.xml');
my $notifier = Monitor::Simple::Notifier->new (config => $config);

# get relevant notifiers
my $result = { service => 'date1',
               code    => Monitor::Simple::RETURN_OK,
               msg     => 'Notifying you...' };
my @relevant_for_1 = $notifier->get_relevant_notifiers ($result);
is (scalar @relevant_for_1, 2, "Number of relevant notifiers for service $result->{service}");

$result->{service} = 'date2';
my @relevant_for_2 = $notifier->get_relevant_notifiers ($result);
is (scalar @relevant_for_2, 1, "Number of relevant notifiers for service $result->{service}");

# extract emails
my @emails = ();
foreach $element (@relevant_for_1) {
    my $extracted = $notifier->extract_emails ($element);
    push (@emails, $extracted);
}
is (scalar @emails, 2,         "Extracted emails 1");
is (scalar @{ $emails[0] }, 1, "Extracted emails 2");
is (scalar @{ $emails[1] }, 3, "Extracted emails 2");
# is_deeply (\@emails,
#            [
#             ['guest6@localhost'],
#             ['guest3@localhost','guest2@localhost','guest@localhost',]
#            ],
#            "Extracted emails");

# creation of the arguments for notifiers
use Data::Dumper;
$result->{service} = 'date3';
$result->{code} = Monitor::Simple::RETURN_WARNING;
my @relevant_for_3 = $notifier->get_relevant_notifiers ($result);
is (scalar @relevant_for_3, 1, "Number of relevant notifiers for service $result->{service}");
{
    my @args = $notifier->create_notifier_args ($relevant_for_3[0], 'msg.file');
    is_deeply (\@args,
               [
                '-file',
                'testing simple monitor',
                '-service',
                'date3',
                '-msg',
                'msg.file'
               ],
               "Create notifier arguments");
}
{
    my @args = $notifier->create_notifier_args ($relevant_for_1[1], 'msg.file');
    is (scalar @args, 6,"Create notifier arguments with emails");
    # is_deeply (\@args,
    #            [
    #             '-emails',
    #             'guest3@localhost,guest2@localhost,guest@localhost',
    #             '-service',
    #             'date1',
    #             '-msg',
    #             'msg.file'
    #            ],
    #            "Create notifier arguments with emails");
}

__END__
