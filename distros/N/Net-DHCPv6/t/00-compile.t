use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.059

use Test::More;

plan tests => 76 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

my @module_files = (
    'Net/DHCPv6.pm',
    'Net/DHCPv6/Constants.pm',
    'Net/DHCPv6/DUID.pm',
    'Net/DHCPv6/Helpers.pm',
    'Net/DHCPv6/Message/Advertise.pm',
    'Net/DHCPv6/Message/Confirm.pm',
    'Net/DHCPv6/Message/Decline.pm',
    'Net/DHCPv6/Message/InformationRequest.pm',
    'Net/DHCPv6/Message/Rebind.pm',
    'Net/DHCPv6/Message/Reconfigure.pm',
    'Net/DHCPv6/Message/RelayForw.pm',
    'Net/DHCPv6/Message/RelayReply.pm',
    'Net/DHCPv6/Message/Release.pm',
    'Net/DHCPv6/Message/Renew.pm',
    'Net/DHCPv6/Message/Reply.pm',
    'Net/DHCPv6/Message/Request.pm',
    'Net/DHCPv6/Message/Solicit.pm',
    'Net/DHCPv6/Option.pm',
    'Net/DHCPv6/Option/AftrName.pm',
    'Net/DHCPv6/Option/Auth.pm',
    'Net/DHCPv6/Option/BootfileParam.pm',
    'Net/DHCPv6/Option/BootfileUrl.pm',
    'Net/DHCPv6/Option/CaptivePortal.pm',
    'Net/DHCPv6/Option/ClientArchType.pm',
    'Net/DHCPv6/Option/ClientFqdn.pm',
    'Net/DHCPv6/Option/ClientId.pm',
    'Net/DHCPv6/Option/ClientLinkLayerAddr.pm',
    'Net/DHCPv6/Option/DnsServers.pm',
    'Net/DHCPv6/Option/DomainList.pm',
    'Net/DHCPv6/Option/ElapsedTime.pm',
    'Net/DHCPv6/Option/Generic.pm',
    'Net/DHCPv6/Option/IAAddr.pm',
    'Net/DHCPv6/Option/IANA.pm',
    'Net/DHCPv6/Option/IAPD.pm',
    'Net/DHCPv6/Option/IAPrefix.pm',
    'Net/DHCPv6/Option/IATA.pm',
    'Net/DHCPv6/Option/InfMaxRt.pm',
    'Net/DHCPv6/Option/InfoRefreshTime.pm',
    'Net/DHCPv6/Option/InterfaceId.pm',
    'Net/DHCPv6/Option/MudUrl.pm',
    'Net/DHCPv6/Option/NewPosixTimezone.pm',
    'Net/DHCPv6/Option/NewTzdbTimezone.pm',
    'Net/DHCPv6/Option/NisDomainName.pm',
    'Net/DHCPv6/Option/NisServers.pm',
    'Net/DHCPv6/Option/NispDomainName.pm',
    'Net/DHCPv6/Option/NispServers.pm',
    'Net/DHCPv6/Option/NtpServer.pm',
    'Net/DHCPv6/Option/ORO.pm',
    'Net/DHCPv6/Option/PdExclude.pm',
    'Net/DHCPv6/Option/Preference.pm',
    'Net/DHCPv6/Option/RSOO.pm',
    'Net/DHCPv6/Option/RapidCommit.pm',
    'Net/DHCPv6/Option/ReconfAccept.pm',
    'Net/DHCPv6/Option/ReconfMsg.pm',
    'Net/DHCPv6/Option/RelayMsg.pm',
    'Net/DHCPv6/Option/RemoteId.pm',
    'Net/DHCPv6/Option/ServerId.pm',
    'Net/DHCPv6/Option/SipServerA.pm',
    'Net/DHCPv6/Option/SipServerD.pm',
    'Net/DHCPv6/Option/SntpServers.pm',
    'Net/DHCPv6/Option/SolMaxRt.pm',
    'Net/DHCPv6/Option/StatusCode.pm',
    'Net/DHCPv6/Option/SubscriberId.pm',
    'Net/DHCPv6/Option/Unicast.pm',
    'Net/DHCPv6/Option/UserClass.pm',
    'Net/DHCPv6/Option/VendorClass.pm',
    'Net/DHCPv6/Option/VendorOpts.pm',
    'Net/DHCPv6/OptionList.pm',
    'Net/DHCPv6/Packet.pm',
    'Net/DHCPv6/Packet/Relay.pm',
    'Net/DHCPv6/X.pm',
    'Net/DHCPv6/X/BadDUID.pm',
    'Net/DHCPv6/X/BadMessage.pm',
    'Net/DHCPv6/X/BadOption.pm',
    'Net/DHCPv6/X/Internal.pm',
    'Net/DHCPv6/X/Truncated.pm'
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

    diag('Running: ', join(', ', map { my $str = $_; $str =~ s/'/\\'/g; q{'}.$str.q{'} }
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



is(scalar(@warnings), 0, 'no warnings found') or diag 'got warnings: ', ( Test::More->can('explain') ? Test::More::explain(\@warnings) : join("\n", '', @warnings) ) if $ENV{AUTHOR_TESTING};


