use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.057

use Test::More;

plan tests => 21;

my @module_files = (
    'OpusVL/FB11X/Model/PreferencesDB.pm',
    'OpusVL/FB11X/Preferences.pm',
    'OpusVL/FB11X/Preferences/Controller/Preferences.pm',
    'OpusVL/FB11X/Preferences/Role/ParameterValueEditing.pm',
    'OpusVL/FB11X/Preferences/Role/PreferencesController.pm',
    'OpusVL/Preferences.pm',
    'OpusVL/Preferences/Hat/preferences.pm',
    'OpusVL/Preferences/RolesFor/Result/PrfOwner.pm',
    'OpusVL/Preferences/RolesFor/ResultSet/PrfOwner.pm',
    'OpusVL/Preferences/RolesFor/Schema.pm',
    'OpusVL/Preferences/Schema.pm',
    'OpusVL/Preferences/Schema/Result/CustomDataUniqueValues.pm',
    'OpusVL/Preferences/Schema/Result/PrfDefault.pm',
    'OpusVL/Preferences/Schema/Result/PrfDefaultValues.pm',
    'OpusVL/Preferences/Schema/Result/PrfOwner.pm',
    'OpusVL/Preferences/Schema/Result/PrfOwnerType.pm',
    'OpusVL/Preferences/Schema/Result/PrfPreference.pm',
    'OpusVL/Preferences/Schema/ResultSet/PrfDefault.pm',
    'OpusVL/Preferences/Schema/ResultSet/PrfDefaultValues.pm',
    'OpusVL/Preferences/Schema/ResultSet/PrfOwnerType.pm'
);



# no fake home requested

my @switches = (
    -d 'blib' ? '-Mblib' : '-Ilib',
);

use File::Spec;
use IPC::Open3;
use IO::Handle;

open my $stdin, '<', File::Spec->devnull or die "can't open devnull: $!";

my @warnings;
for my $lib (@module_files)
{
    # see L<perlfaq8/How can I capture STDERR from an external command?>
    my $stderr = IO::Handle->new;

    diag('Running: ', join(', ', map { my $str = $_; $str =~ s/'/\\'/g; q{'} . $str . q{'} }
            $^X, @switches, '-e', "require q[$lib]"))
        if $ENV{PERL_COMPILE_TEST_DEBUG};

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, @switches, '-e', "require q[$lib]");
    binmode $stderr, ':crlf' if $^O eq 'MSWin32';
    my @_warnings = <$stderr>;
    waitpid($pid, 0);
    is($?, 0, "$lib loaded ok");

    shift @_warnings if @_warnings and $_warnings[0] =~ /^Using .*\bblib/
        and not eval { +require blib; blib->VERSION('1.01') };

    if (@_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
}



is(scalar(@warnings), 0, 'no warnings found')
    or diag 'got warnings: ', ( Test::More->can('explain') ? Test::More::explain(\@warnings) : join("\n", '', @warnings) );


