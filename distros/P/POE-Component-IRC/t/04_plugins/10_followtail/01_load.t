use strict;
use warnings FATAL => 'all';
use File::Temp qw(tempfile);
use POE qw(Filter::Line);
use POE::Component::IRC;
use POE::Component::IRC::Plugin::FollowTail;
use Test::More tests => 5;

my ($temp_fh, $temp_file) = tempfile(UNLINK => 1);
my $inode = (stat $temp_fh)[1];
$temp_fh->autoflush(1);
print $temp_fh "moocow\n";

my $bot = POE::Component::IRC->spawn( plugin_debug => 1 );

POE::Session->create(
    package_states => [
        main => [ qw(_start irc_plugin_add irc_plugin_del irc_tail_input) ],
    ],
);

$poe_kernel->run();

sub _start {
    $bot->yield(register => 'all');

    my $plugin = POE::Component::IRC::Plugin::FollowTail->new(
        filename => $temp_file,
        filter   => POE::Filter::Line->new(),
    );

    isa_ok($plugin, 'POE::Component::IRC::Plugin::FollowTail');

    if (!$bot->plugin_add('TestPlugin', $plugin) ) {
        fail('plugin_add failed');
        $bot->yield('shutdown');
    }
}

sub irc_plugin_add {
    my ($name, $plugin) = @_[ARG0, ARG1];
    return if $name ne 'TestPlugin';

    isa_ok($plugin, 'POE::Component::IRC::Plugin::FollowTail');
    print $temp_fh "Cows go moo, yes they do\n";
}

sub irc_tail_input {
    my ($sender, $filename, $input) = @_[SENDER, ARG0, ARG1];
    my $irc = $sender->get_heap();

    SKIP: {
        skip "No inodes on Windows", 1 if $^O eq 'MSWin32';
        is((stat $filename)[1], $inode, 'Filename is okay');
    }
    is($input, 'Cows go moo, yes they do', 'Cows go moo!');

    if (!$irc->plugin_del('TestPlugin')) {
        fail('plugin_del failed');
        $irc->yield('shutdown');
    }
}

sub irc_plugin_del {
    my ($sender, $name, $plugin) = @_[SENDER, ARG0, ARG1];
    my $irc = $sender->get_heap();
    return if $name ne 'TestPlugin';

    isa_ok($plugin, 'POE::Component::IRC::Plugin::FollowTail');
    $irc->yield('shutdown');
}
