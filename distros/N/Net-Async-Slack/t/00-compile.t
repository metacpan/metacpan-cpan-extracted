use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.058

use Test::More;

plan tests => 105 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

my @module_files = (
    'Net/Async/Slack.pm',
    'Net/Async/Slack/Commands.pm',
    'Net/Async/Slack/Event/AccountsChanged.pm',
    'Net/Async/Slack/Event/AppHomeOpened.pm',
    'Net/Async/Slack/Event/AppMention.pm',
    'Net/Async/Slack/Event/AppRateLimited.pm',
    'Net/Async/Slack/Event/AppUninstalled.pm',
    'Net/Async/Slack/Event/BlockActions.pm',
    'Net/Async/Slack/Event/Bot.pm',
    'Net/Async/Slack/Event/BotAdded.pm',
    'Net/Async/Slack/Event/BotChanged.pm',
    'Net/Async/Slack/Event/Channel.pm',
    'Net/Async/Slack/Event/ChannelArchive.pm',
    'Net/Async/Slack/Event/ChannelCreated.pm',
    'Net/Async/Slack/Event/ChannelDeleted.pm',
    'Net/Async/Slack/Event/ChannelHistoryChanged.pm',
    'Net/Async/Slack/Event/ChannelJoined.pm',
    'Net/Async/Slack/Event/ChannelLeft.pm',
    'Net/Async/Slack/Event/ChannelMarked.pm',
    'Net/Async/Slack/Event/ChannelRename.pm',
    'Net/Async/Slack/Event/ChannelUnarchive.pm',
    'Net/Async/Slack/Event/CommandsChanged.pm',
    'Net/Async/Slack/Event/DndUpdated.pm',
    'Net/Async/Slack/Event/DndUpdatedUser.pm',
    'Net/Async/Slack/Event/EmailDomainChanged.pm',
    'Net/Async/Slack/Event/EmojiChanged.pm',
    'Net/Async/Slack/Event/FileChange.pm',
    'Net/Async/Slack/Event/FileCommentAdded.pm',
    'Net/Async/Slack/Event/FileCommentDeleted.pm',
    'Net/Async/Slack/Event/FileCommentEdited.pm',
    'Net/Async/Slack/Event/FileCreated.pm',
    'Net/Async/Slack/Event/FileDeleted.pm',
    'Net/Async/Slack/Event/FilePublic.pm',
    'Net/Async/Slack/Event/FileShared.pm',
    'Net/Async/Slack/Event/FileUnshared.pm',
    'Net/Async/Slack/Event/Goodbye.pm',
    'Net/Async/Slack/Event/GridMigrationFinished.pm',
    'Net/Async/Slack/Event/GridMigrationStarted.pm',
    'Net/Async/Slack/Event/GroupArchive.pm',
    'Net/Async/Slack/Event/GroupClose.pm',
    'Net/Async/Slack/Event/GroupDeleted.pm',
    'Net/Async/Slack/Event/GroupHistoryChanged.pm',
    'Net/Async/Slack/Event/GroupJoined.pm',
    'Net/Async/Slack/Event/GroupLeft.pm',
    'Net/Async/Slack/Event/GroupMarked.pm',
    'Net/Async/Slack/Event/GroupOpen.pm',
    'Net/Async/Slack/Event/GroupRename.pm',
    'Net/Async/Slack/Event/GroupUnarchive.pm',
    'Net/Async/Slack/Event/Hello.pm',
    'Net/Async/Slack/Event/ImClose.pm',
    'Net/Async/Slack/Event/ImCreated.pm',
    'Net/Async/Slack/Event/ImHistoryChanged.pm',
    'Net/Async/Slack/Event/ImMarked.pm',
    'Net/Async/Slack/Event/ImOpen.pm',
    'Net/Async/Slack/Event/LinkShared.pm',
    'Net/Async/Slack/Event/ManualPresenceChange.pm',
    'Net/Async/Slack/Event/MemberJoinedChannel.pm',
    'Net/Async/Slack/Event/MemberLeftChannel.pm',
    'Net/Async/Slack/Event/Message.pm',
    'Net/Async/Slack/Event/MessageAction.pm',
    'Net/Async/Slack/Event/MessageAppHome.pm',
    'Net/Async/Slack/Event/MessageChannels.pm',
    'Net/Async/Slack/Event/MessageGroups.pm',
    'Net/Async/Slack/Event/MessageIm.pm',
    'Net/Async/Slack/Event/MessageMpim.pm',
    'Net/Async/Slack/Event/PinAdded.pm',
    'Net/Async/Slack/Event/PinRemoved.pm',
    'Net/Async/Slack/Event/PrefChange.pm',
    'Net/Async/Slack/Event/PresenceChange.pm',
    'Net/Async/Slack/Event/PresenceQuery.pm',
    'Net/Async/Slack/Event/PresenceSub.pm',
    'Net/Async/Slack/Event/ReactionAdded.pm',
    'Net/Async/Slack/Event/ReactionRemoved.pm',
    'Net/Async/Slack/Event/ReconnectURL.pm',
    'Net/Async/Slack/Event/ResourcesAdded.pm',
    'Net/Async/Slack/Event/ResourcesRemoved.pm',
    'Net/Async/Slack/Event/ScopeDenied.pm',
    'Net/Async/Slack/Event/ScopeGranted.pm',
    'Net/Async/Slack/Event/StarAdded.pm',
    'Net/Async/Slack/Event/StarRemoved.pm',
    'Net/Async/Slack/Event/SubteamCreated.pm',
    'Net/Async/Slack/Event/SubteamMembersChanged.pm',
    'Net/Async/Slack/Event/SubteamSelfAdded.pm',
    'Net/Async/Slack/Event/SubteamSelfRemoved.pm',
    'Net/Async/Slack/Event/SubteamUpdated.pm',
    'Net/Async/Slack/Event/TeamDomainChange.pm',
    'Net/Async/Slack/Event/TeamJoin.pm',
    'Net/Async/Slack/Event/TeamMigrationStarted.pm',
    'Net/Async/Slack/Event/TeamPlanChange.pm',
    'Net/Async/Slack/Event/TeamPrefChange.pm',
    'Net/Async/Slack/Event/TeamProfileChange.pm',
    'Net/Async/Slack/Event/TeamProfileDelete.pm',
    'Net/Async/Slack/Event/TeamProfileReorder.pm',
    'Net/Async/Slack/Event/TeamRename.pm',
    'Net/Async/Slack/Event/TokensRevoked.pm',
    'Net/Async/Slack/Event/URLVerification.pm',
    'Net/Async/Slack/Event/UserChange.pm',
    'Net/Async/Slack/Event/UserResourceDenied.pm',
    'Net/Async/Slack/Event/UserResourceGranted.pm',
    'Net/Async/Slack/Event/UserResourceRemoved.pm',
    'Net/Async/Slack/Event/UserTyping.pm',
    'Net/Async/Slack/EventType.pm',
    'Net/Async/Slack/Message.pm',
    'Net/Async/Slack/RTM.pm',
    'Net/Async/Slack/Socket.pm'
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


