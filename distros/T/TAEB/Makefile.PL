# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Define metadata
name           'TAEB';
all_from       'lib/TAEB.pm';

# the object system
requires 'Moose'                       => 0.71;
requires 'MooseX::AttributeHelpers'    => 0.09;
requires 'MooseX::ClassAttribute'      => 0.07;
requires 'MooseX::Role::Parameterized' => 0.04;
requires 'MooseX::Role::Matcher'       => 0.03;
requires 'Module::Pluggable';

# parse escape codes into an addressable screen
requires 'Term::VT102::ZeroBased';

# print on an addressable screen
requires 'Curses';

# logging
requires 'Log::Dispatch::Channels';

# config
requires 'YAML';
requires 'Hash::Merge';
requires 'File::HomeDir';

# TAEB::Util
requires 'Sub::Exporter';
requires 'List::MoreUtils';

# pathfinding
requires 'Heap::Simple';
requires 'Heap::Simple::XS'; # why doesn't Heap::Simple do this for us...

# miscellaneous
requires 'Time::HiRes';
requires 'Data::Page';

# NetHack-specific things
requires 'NetHack::Menu' => 0.06;
requires 'NetHack::FOV'  => 0.01;
requires 'NetHack::Item' => 0.08;

if (!can_run('nethack')) {
    warn << '__NETHACK__';
******************************************************************
It appears that you do not have a "nethack" binary available. You will not be
able to use TAEB's Local interface until you install nethack.

Alternatively, use the Telnet interface for playing on public servers such as
nethack.alt.org. Be sure that the "server nethack" dependencies are satisfied.
******************************************************************
__NETHACK__

    # Give them some time to read.
    sleep 10;
}

features(
    # optional modules that enhance TAEB's playing
    'TAEB for server NetHack' => [
        -default => 0,
        recommends('IO::Socket::Telnet'),
    ],
    'TAEB for local NetHack' => [
        -default => 0,
        recommends('IO::Pty::Easy' => 0.05),
    ],

    # debugging tools
    'REPL on ~' => [
        -default => 1,
        recommends('Carp::REPL'),
    ],
    'IRC debug interface' => [
        -default => 0,
        recommends('Bot::BasicBot'),
        recommends('App::Nopaste'),
    ],
    'Log errors (and eventually deaths) to Twitter' => [
        -default => 0,
        recommends('Log::Dispatch::Twitter'),
    ],
    'Compress backed up logfiles' => [
        -default => 1,
        recommends('IO::Compress::Gzip'),
    ],
);

build_requires 'Test::More';

install_script 'bin/taeb';

tests('t/*.t t/*/*.t');

auto_install;
WriteAll;

