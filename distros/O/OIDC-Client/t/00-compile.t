use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.058

use Test::More;

plan tests => 21 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

my @module_files = (
    'OIDC/Client.pm',
    'OIDC/Client/AccessToken.pm',
    'OIDC/Client/AccessTokenBuilder.pm',
    'OIDC/Client/ApiUserAgentBuilder.pm',
    'OIDC/Client/Error.pm',
    'OIDC/Client/Error/Authentication.pm',
    'OIDC/Client/Error/InvalidResponse.pm',
    'OIDC/Client/Error/Provider.pm',
    'OIDC/Client/Error/TokenValidation.pm',
    'OIDC/Client/Identity.pm',
    'OIDC/Client/Plugin.pm',
    'OIDC/Client/ResponseParser.pm',
    'OIDC/Client/Role/AttributesManager.pm',
    'OIDC/Client/Role/ClaimsValidator.pm',
    'OIDC/Client/Role/ClientAuthenticationHelper.pm',
    'OIDC/Client/Role/ConfigurationChecker.pm',
    'OIDC/Client/Role/LoggerWrapper.pm',
    'OIDC/Client/TokenResponse.pm',
    'OIDC/Client/TokenResponseParser.pm',
    'OIDC/Client/User.pm',
    'OIDC/Client/Utils.pm'
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


