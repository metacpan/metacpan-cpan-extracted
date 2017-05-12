use strict;
use warnings;

use Module::Build 0.28;

use File::Spec;
use FindBin;

## External Dependencies

my $REMIND = 'remind';
my $TEST_REMINDERS = File::Spec->catfile($FindBin::Bin, 't', '000_reminders');
print "Checking for `$REMIND`... ";

my $rem = `$REMIND -n $TEST_REMINDERS`;
if ($? || ! defined $rem) {
    die "Failed to run a test $REMIND command. Is remind installed?";
}
if ($rem !~ qr#^\d{4}/\d\d/\d\d it works!$#) {
    die "Remind output didn't look right; got: $rem";
}
print "ok.\n";

## Build config

my $build = Module::Build->new(
    module_name     => 'Remind::Client',
    license         => 'perl',
    sign            => 1,
    configure_requires  => {
        'Module::Build' => 0.28, # for meta_merge
    },
    build_requires  => {
        'File::Temp' => 0.14, # for tests
        'Module::Build' => 0.28,
        'POSIX' => 0, # for tests
        'Test::More' => 0.81_01, # for note()
        'Test::NoWarnings' => 0,
        'Test::Warn' => 0,
    },
    requires => {
        'Carp' => 0,
        'File::HomeDir' => 0.50,
        'IO::Handle' => 0,
        'IPC::Open2' => 0,
    },
    meta_merge => {
        resources => {
            repository => 'http://git.pioto.org/gitweb/Remind-Client.git',
            license => 'http://dev.perl.org/licenses/',
            bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Remind-Client',
        },
    },
);
$build->create_build_script();

