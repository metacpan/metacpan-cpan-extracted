use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.058

use Test::More;

plan tests => 32 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

my @module_files = (
    'Selenium/ActionChains.pm',
    'Selenium/CanStartBinary.pm',
    'Selenium/CanStartBinary/FindBinary.pm',
    'Selenium/CanStartBinary/ProbePort.pm',
    'Selenium/Chrome.pm',
    'Selenium/Edge.pm',
    'Selenium/Firefox.pm',
    'Selenium/Firefox/Binary.pm',
    'Selenium/Firefox/Profile.pm',
    'Selenium/InternetExplorer.pm',
    'Selenium/PhantomJS.pm',
    'Selenium/Remote/Commands.pm',
    'Selenium/Remote/Driver.pm',
    'Selenium/Remote/Driver/CanSetWebdriverContext.pm',
    'Selenium/Remote/Driver/Firefox/Profile.pm',
    'Selenium/Remote/ErrorHandler.pm',
    'Selenium/Remote/Finders.pm',
    'Selenium/Remote/Mock/Commands.pm',
    'Selenium/Remote/Mock/RemoteConnection.pm',
    'Selenium/Remote/RemoteConnection.pm',
    'Selenium/Remote/Spec.pm',
    'Selenium/Remote/WDKeys.pm',
    'Selenium/Remote/WebElement.pm',
    'Selenium/Waiter.pm',
    'Test/Selenium/Chrome.pm',
    'Test/Selenium/Edge.pm',
    'Test/Selenium/Firefox.pm',
    'Test/Selenium/InternetExplorer.pm',
    'Test/Selenium/PhantomJS.pm',
    'Test/Selenium/Remote/Driver.pm',
    'Test/Selenium/Remote/Role/DoesTesting.pm',
    'Test/Selenium/Remote/WebElement.pm'
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
    or diag 'got warnings: ', ( Test::More->can('explain') ? Test::More::explain(\@warnings) : join("\n", '', @warnings) ) if $ENV{AUTHOR_TESTING};


