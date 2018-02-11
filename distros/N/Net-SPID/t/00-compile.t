use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.058

use Test::More;

plan tests => 22 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

my @module_files = (
    'Net/SAML2.pm',
    'Net/SAML2/Binding/POST.pm',
    'Net/SAML2/Binding/Redirect.pm',
    'Net/SAML2/Binding/SOAP.pm',
    'Net/SAML2/IdP.pm',
    'Net/SAML2/Protocol/ArtifactResolve.pm',
    'Net/SAML2/Protocol/Assertion.pm',
    'Net/SAML2/Protocol/AuthnRequest.pm',
    'Net/SAML2/Protocol/LogoutRequest.pm',
    'Net/SAML2/Protocol/LogoutResponse.pm',
    'Net/SAML2/Role/ProtocolMessage.pm',
    'Net/SAML2/SP.pm',
    'Net/SAML2/XML/Sig.pm',
    'Net/SPID.pm',
    'Net/SPID/OpenID.pm',
    'Net/SPID/SAML.pm',
    'Net/SPID/SAML/Assertion.pm',
    'Net/SPID/SAML/AuthnRequest.pm',
    'Net/SPID/SAML/IdP.pm',
    'Net/SPID/SAML/LogoutRequest.pm',
    'Net/SPID/SAML/LogoutResponse.pm',
    'Net/SPID/Session.pm'
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


