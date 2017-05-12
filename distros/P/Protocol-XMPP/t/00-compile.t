use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.044

use Test::More  tests => 34 + ($ENV{AUTHOR_TESTING} ? 1 : 0);



my @module_files = (
    'Protocol/XMPP.pm',
    'Protocol/XMPP/Base.pm',
    'Protocol/XMPP/Contact.pm',
    'Protocol/XMPP/Element/Active.pm',
    'Protocol/XMPP/Element/Auth.pm',
    'Protocol/XMPP/Element/Bind.pm',
    'Protocol/XMPP/Element/Body.pm',
    'Protocol/XMPP/Element/Challenge.pm',
    'Protocol/XMPP/Element/Feature.pm',
    'Protocol/XMPP/Element/Features.pm',
    'Protocol/XMPP/Element/HTML.pm',
    'Protocol/XMPP/Element/IQ.pm',
    'Protocol/XMPP/Element/JID.pm',
    'Protocol/XMPP/Element/Mechanism.pm',
    'Protocol/XMPP/Element/Mechanisms.pm',
    'Protocol/XMPP/Element/Message.pm',
    'Protocol/XMPP/Element/Nick.pm',
    'Protocol/XMPP/Element/Presence.pm',
    'Protocol/XMPP/Element/Proceed.pm',
    'Protocol/XMPP/Element/Register.pm',
    'Protocol/XMPP/Element/Response.pm',
    'Protocol/XMPP/Element/Session.pm',
    'Protocol/XMPP/Element/StartTLS.pm',
    'Protocol/XMPP/Element/Stream.pm',
    'Protocol/XMPP/Element/Subject.pm',
    'Protocol/XMPP/Element/Success.pm',
    'Protocol/XMPP/ElementBase.pm',
    'Protocol/XMPP/Handler.pm',
    'Protocol/XMPP/IQ/Roster.pm',
    'Protocol/XMPP/Message.pm',
    'Protocol/XMPP/Roster.pm',
    'Protocol/XMPP/Stream.pm',
    'Protocol/XMPP/TextElement.pm',
    'Protocol/XMPP/User.pm'
);



# no fake home requested

my $inc_switch = -d 'blib' ? '-Mblib' : '-Ilib';

use File::Spec;
use IPC::Open3;
use IO::Handle;

open my $stdin, '<', File::Spec->devnull or die "can't open devnull: $!";

my @warnings;
for my $lib (@module_files)
{
    # see L<perlfaq8/How can I capture STDERR from an external command?>
    my $stderr = IO::Handle->new;

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, $inc_switch, '-e', "require q[$lib]");
    binmode $stderr, ':crlf' if $^O eq 'MSWin32';
    my @_warnings = <$stderr>;
    waitpid($pid, 0);
    is($?, 0, "$lib loaded ok");

    if (@_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
}



is(scalar(@warnings), 0, 'no warnings found') if $ENV{AUTHOR_TESTING};


