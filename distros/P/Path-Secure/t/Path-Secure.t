#!/usr/bin/env perl
use 5.014;
use strict;
use warnings FATAL => 'all';
use re '/aa';
use Test2::V0;
use Test2::Plugin::NoWarnings;
use Test::MockModule qw{strict};
use FindBin::libs;

use Cwd        qw{realpath};
use Errno      qw{EINVAL ENOENT ENOTDIR};
use Fcntl      qw{S_IFDIR S_IFLNK S_IFREG};
use POSIX      qw{strerror};
use File::Temp qw{tempdir};

use Path::Secure qw{exposed secure};

# The real subs, for mocks that pass through to them.  A mock that called
# $mock->original would hold $mock, which then never restores the sub.
my $stat_entry  = \&Path::Secure::stat_entry;
my $change_mode = \&Path::Secure::change_mode;

subtest 'exposed: a tree that stat_entry makes up' => sub {
    my $mock  = Test::MockModule->new('Path::Secure');
    my $other = $> + 1;
    my %tree  = (
        '/'             => [ 0,      S_IFDIR | oct 755 ],
        '/bogus'        => [ 0,      S_IFDIR | oct 1777 ],
        '/bogus/mine'   => [ $>,     S_IFREG | oct 600 ],
        '/bogus/roots'  => [ 0,      S_IFREG | oct 644 ],
        '/bogus/theirs' => [ $other, S_IFREG | oct 600 ],
    );
    $mock->redefine(
        stat_entry => sub {
            my ($path) = @_;
            my ( $uid, $mode ) = @{ $tree{$path} or die "the test asked about $path, which its tree does not have\n" };
            return ( 1, 1, $mode, 1, $uid, 1, 0, 0, 0, 0, 0, 4096, 0 );
        }
    );
    is( exposed('/bogus/mine'),   undef,                                'what I own, in a sticky directory that root owns, is safe' );
    is( exposed('/bogus/roots'),  undef,                                'what root owns is safe' );
    is( exposed('/bogus/theirs'), "another account owns /bogus/theirs", 'what another account owns, in the same directory, is exposed' );
    is( exposed('/bogus'),        "every account can write /bogus",     'the sticky directory itself is exposed, as the path' );
};

# The real path, so that the reasons name what exposed names when TMPDIR
# itself is reached through a symbolic link.
my $base = realpath( tempdir( CLEANUP => 1 ) );
chmod oct 700, $base or die "chmod $base: $!\n";

# Every case below starts from $base, and asserts what one change to it does.
# If $base is not safe to begin with, none of them can say anything.
my $start = exposed($base);
if ( defined $start ) {
    note "the temporary directory is exposed before any test starts, so the tests that use it cannot run: $start";
    done_testing;
    exit 0;
}

# A file that is safe, in a directory that is safe.
sub make_file {
    my ( $path, $mode ) = @_;
    open my $fh, '>', $path or die "open $path: $!\n";
    close $fh or die "close $path: $!\n";
    chmod $mode, $path or die "chmod $path: $!\n";
    return $path;
}

sub make_dir {
    my ( $path, $mode ) = @_;
    mkdir $path or die "mkdir $path: $!\n";
    chmod $mode, $path or die "chmod $path: $!\n";
    return $path;
}

sub make_link {
    my ( $to, $path ) = @_;
    symlink $to, $path or die "symlink $path: $!\n";
    return $path;
}

my $safe  = make_file( "$base/safe", oct 600 );
my $group = ( stat $safe )[5];

subtest 'exposed: modes of the path itself' => sub {
    is( exposed($safe), undef, 'a file that only its owner can write, in directories that only their owners can write, is safe' );
    is( exposed('/'),   undef, 'the root directory, which root owns, is safe' );

    my $gw = make_file( "$base/group-writable", oct 620 );
    is( exposed($gw), "the group of $gw can write it", 'a file that its group can write is exposed' );
    is( exposed( $gw, trust_group => $group ),                 undef,                           'a file that its group can write is safe when that group is trusted' );
    is( exposed( $gw, trust_group => [ $group + 1, $group ] ), undef,                           'trust_group takes a list of groups, and any of them is trusted' );
    is( exposed( $gw, trust_group => $group + 1 ),             "the group of $gw can write it", 'trust in another group does not pass the group of the file' );
    is( exposed( $gw, trust_group => [] ),                     "the group of $gw can write it", 'an empty list of groups trusts none' );

    my $ww = make_file( "$base/world-writable", oct 602 );
    is( exposed($ww),                          "every account can write $ww", 'a file that every account can write is exposed' );
    is( exposed( $ww, trust_group => $group ), "every account can write $ww", 'trust in its group does not pass a file that every account can write' );
};

subtest 'exposed: directories above the path' => sub {
    my $open = make_dir( "$base/open", oct 777 );
    my $in   = make_file( "$open/file", oct 600 );
    is( exposed($in), "every account can write $open", 'a file in a directory that every account can write is exposed' );

    my $shared = make_dir( "$base/shared", oct 770 );
    my $deep   = make_dir( "$shared/deep", oct 700 );
    my $below  = make_file( "$deep/file", oct 600 );
    is( exposed($below),                          "the group of $shared can write it", 'a directory that its group can write, anywhere above the path, exposes it' );
    is( exposed( $below, trust_group => $group ), undef,                               'a directory that a trusted group can write does not' );

    my $sticky = make_dir( "$base/sticky", oct 1777 );
    my $mine   = make_file( "$sticky/file", oct 600 );
    is( exposed($mine),                         undef,                             'a directory above the path with the sticky bit is safe, because nobody can rename what I own in it' );
    is( exposed($sticky),                       "every account can write $sticky", 'the path itself gets no pass for the sticky bit' );
    is( exposed( $sticky, sticky_target => 1 ), undef,                             'unless sticky_target asks for one' );
    my $gsticky = make_dir( "$base/group-sticky", oct 1770 );
    is( exposed( $gsticky, sticky_target => 1 ), undef, 'sticky_target passes a directory that its group can write, as well as every account' );
    my $ww_file = make_file( "$base/sticky-file", oct 1602 );
    is( exposed( $ww_file, sticky_target => 1 ), "every account can write $ww_file", 'sticky_target passes only a directory, since the sticky bit does nothing for a file' );

    is( exposed("$open/../safe"), undef, 'a directory that the path leaves by .. is not above what it names' );
};

subtest 'exposed: a path that is not there' => sub {
    is( exposed("$base/bogus"),        "$base/bogus is not there",                          'a path that is not there gets a reason, not undef' );
    is( exposed("$base/bogus/deeper"), "$base/bogus is not there",                          'the reason names the first part that is not there' );
    is( exposed("$safe/deeper"),       "cannot look at $safe/deeper: " . strerror(ENOTDIR), 'a part that cannot be looked at gets the error from the system' );
};

subtest 'exposed: symbolic links' => sub {
    my $open = make_dir( "$base/links-open", oct 777 );

    my $repointable = make_link( $safe, "$open/link" );
    is( exposed($repointable), "every account can write $open", 'a link in a directory that every account can write is exposed, because anyone can repoint it' );

    my $into = make_link( "$open/target", "$base/into" );
    make_file( "$open/target", oct 600 );
    is( exposed($into), "every account can write $open", 'a link to a file in a directory that every account can write is exposed' );

    make_link( $safe, "$open/hop" );
    my $chain = make_link( "$open/hop", "$base/chain" );
    is( exposed($chain), "every account can write $open", 'each link of a chain is checked, not only where the chain ends' );

    my $fine = make_link( 'safe', "$base/relative" );
    is( exposed($fine), undef, 'a relative link between directories that are safe is safe' );

    my $sub = make_dir( "$base/sub", oct 700 );
    my $up  = make_link( '..', "$sub/up" );
    is( exposed($up), undef, 'a link to .. names the directory above it, which is checked as the path' );

    my $dot = make_link( q{.}, "$sub/dot" );
    is( exposed("$dot/dot/dot/up"), undef, 'a link to . names the directory that holds it' );

    my $above_root = make_link( '../' x 64, "$sub/above-root" );
    is( exposed($above_root), undef, 'a link that climbs past / stops at /, as the kernel does, and / is safe' );

    my $loop = make_link( "$base/loop", "$base/loop" );
    is( exposed($loop), "$loop names more than 40 symbolic links", 'a loop of links gets a reason' );

    my $dangling = make_link( "$base/bogus-target", "$base/dangling" );
    is( exposed($dangling), "$base/bogus-target is not there", 'a link to nothing names what is not there' );
};

subtest 'exposed: relative paths' => sub {
    my $here = realpath(q{.});
    chdir $base or die "chdir $base: $!\n";
    my @got = ( exposed('safe'), exposed('bogus'), exposed('./safe') );
    chdir $here or die "chdir $here: $!\n";
    is( \@got, [ undef, "$base/bogus is not there", undef ], 'a relative path is taken from the current directory, and a reason names its absolute path' );
};

subtest 'exposed: owners, through stat_entry' => sub {
    my $mock  = Test::MockModule->new('Path::Secure');
    my $other = $> + 1;
    my %owner;
    $mock->redefine(
        stat_entry => sub {
            my ($path) = @_;
            my @status = $stat_entry->($path);
            $status[4] = $owner{$path} if @status && exists $owner{$path};
            return @status;
        }
    );

    %owner = ( $safe => $other );
    is( exposed($safe), "another account owns $safe", 'a file that another account owns is exposed' );

    %owner = ( $base => $other );
    is( exposed($safe), "another account owns $base", 'a directory above the path that another account owns exposes it' );

    my $sticky = make_dir( "$base/owned-sticky", oct 1777 );
    %owner = ( $sticky => $other );
    is( exposed( $sticky, sticky_target => 1 ), "another account owns $sticky", 'the sticky bit does not pass a directory that another account owns' );

    my $link = make_link( $safe, "$base/owned-link" );
    %owner = ( $link => $other );
    is( exposed($link), "another account owns the symbolic link $link", 'a link that another account owns is exposed, because in a sticky directory its owner can still replace it' );

    %owner = ( $safe => 0 );
    is( exposed($safe), undef, 'a file that root owns is safe, because root can change anything anyway' );
};

subtest 'exposed: a stat_entry that says every entry is a link' => sub {
    my $mock = Test::MockModule->new('Path::Secure');
    $mock->redefine(
        stat_entry => sub {
            my ($path) = @_;
            my @status = $stat_entry->($path);
            $status[2] = S_IFLNK | oct 755 if @status;
            return @status;
        }
    );
    my ($first) = $safe =~ m{\A(/[^/]+)}sx;
    is( exposed($safe), "cannot read the symbolic link $first: " . strerror(EINVAL), 'a link that readlink cannot read gives a reason, rather than loop' );
};

subtest 'exposed: what it refuses' => sub {
    is( dies { exposed() },                                   "exposed needs a path\n",                                                  'no path dies' );
    is( dies { exposed(q{}) },                                "exposed needs a path\n",                                                  'an empty path dies' );
    is( dies { exposed( $safe, 'trust_group' ) },             "exposed takes a path and then pairs of options and their values\n",       'an option without a value dies' );
    is( dies { exposed( $safe, trust_gruop => 1 ) },          "exposed does not know the option trust_gruop\n",                          'a misspelled option dies, rather than be ignored' );
    is( dies { exposed( $safe, trust_group => 'wheel' ) },    "trust_group takes a gid or a reference to an array of gids, not wheel\n", 'a group name dies' );
    is( dies { exposed( $safe, trust_group => undef ) },      "trust_group takes a gid or a reference to an array of gids, not undef\n", 'an undefined group dies, rather than trust none' );
    is( dies { exposed( $safe, trust_group => { 1 => 1 } ) }, "trust_group takes a gid or a reference to an array of gids, not HASH\n",  'a hash of groups dies' );
    is( dies { exposed( $safe, trust_group => [ 1, -1 ] ) },  "trust_group takes a gid or a reference to an array of gids, not -1\n",    'a negative group dies' );

    local $^O = 'MSWin32';
    is( dies { exposed($safe) }, "Path::Secure cannot tell who can change a path on MSWin32, whose files do not have POSIX owners and modes\n", 'a system without POSIX owners and modes dies rather than say safe' );
};

# The mode bits of $path that chmod sets.
sub mode_of {
    my ($path) = @_;
    return ( stat $path )[2] & oct 7777;
}

# A workspace that a group shares, under $base: $name, its repo, and a file in
# the repo, with the modes that a umask of 0002 gives.
sub workspace {
    my ($name) = @_;
    my $ws     = make_dir( "$base/$name", oct 770 );
    my $repo   = make_dir( "$ws/repo",    oct 775 );
    my $file   = make_file( "$repo/config", oct 664 );
    return ( $ws, $repo, $file );
}

subtest 'secure: the path itself' => sub {
    my $top = make_dir( "$base/secure-self", oct 700 );

    my $fine = make_file( "$top/fine", oct 640 );
    is( [ secure( $fine, upto => $top ) ], [],      'a path that is safe already changes nothing' );
    is( mode_of($fine),                    oct 640, 'and keeps its mode' );

    my $open = make_file( "$top/open", oct 4666 );
    is( [ secure( $open, upto => $top ) ], [$open],  'a path that its group and every account can write is changed' );
    is( mode_of($open),                    oct 4644, 'they lose their write bits, and the other bits stay' );
    is( exposed($open),                    undef,    'and exposed finds nothing' );

    my $shared = make_file( "$top/shared", oct 666 );
    is( [ secure( $shared, upto => $top, trust_group => $group ) ], [$shared], 'a trusted group keeps its write bit' );
    is( mode_of($shared),                                           oct 664,   'only every account loses it' );

    is( [ secure( $top, upto => $top ) ], [], 'upto may be the path itself' );
};

subtest 'secure: the directories above the path' => sub {
    my ( $ws, $repo, $file ) = workspace('sticky-ws');
    is( [ secure( $file, upto => $ws ) ],          [ $ws, $repo, $file ], 'each directory that its group can write is changed, from the top down, and the path' );
    is( [ map { mode_of($_) } $ws, $repo, $file ], [ oct 1770, oct 1775, oct 644 ], 'the directories get the sticky bit and keep their write bits, and the path loses them' );
    is( exposed($file),                            undef, 'and exposed finds nothing' );

    my ( $pws, $prepo, $pfile ) = workspace('private-ws');
    is( [ secure( $pfile, upto => $pws, private => 1 ) ], [ $pws, $prepo, $pfile ], 'private changes the same directories' );
    is( [ map { mode_of($_) } $pws, $prepo, $pfile ], [ oct 750, oct 755, oct 644 ], 'but takes their write bits away rather than add the sticky bit' );

    my ( $tws, undef, $tfile ) = workspace('trusted-ws');
    is( [ secure( $tfile, upto => $tws, trust_group => $group ) ], [], 'nothing changes when the group that can write is trusted' );

    my $sticky = make_dir( "$base/sticky-top", oct 1777 );
    my $deep   = make_dir( "$sticky/deep",     oct 700 );
    is( [ secure( $deep, upto => $sticky ) ], [], 'a directory above that is sticky already is not changed' );
};

subtest 'secure: what it refuses, having changed nothing' => sub {
    my ( $ws, $repo, $file ) = workspace('refused-ws');
    is( dies { secure($file) }, "secure needs upto, the highest directory that it may change\n", 'no upto dies' );
    is( dies { secure( $file,         upto => "$base/bogus" ) }, "$base/bogus is not there\n", 'an upto that is not there dies' );
    is( dies { secure( $file,         upto => $file ) },         "$file is not a directory\n", 'an upto that is not a directory dies' );
    is( dies { secure( "$repo/bogus", upto => $ws ) },           "$repo/bogus is not there\n", 'a path that is not there dies' );
    my $elsewhere = make_dir( "$base/elsewhere", oct 700 );
    is( dies { secure( $file, upto => $elsewhere ) },      "$file is not in $elsewhere\n",                                   'a path that is not in upto dies' );
    is( dies { secure( $file, upto => $repo ) },           "secure cannot make $file safe: the group of $ws can write it\n", 'a directory above upto that stays exposed dies' );
    is( dies { secure( $file, upto => $ws, bogus => 1 ) }, "secure does not know the option bogus\n",                        'an option that it does not know dies' );
    is( [ map { mode_of($_) } $ws, $repo, $file ],         [ oct 770, oct 775, oct 664 ],                                    'none of them changed a mode' );

    my $top  = make_dir( "$base/link-ws", oct 700 );
    my $open = make_dir( "$top/open",     oct 777 );
    my $real = make_file( "$top/real", oct 666 );
    my $link = make_link( $real, "$open/link" );
    is( dies { secure( $link, upto => $top ) }, "secure cannot make $link safe: every account can write $open\n", 'a link in a directory that it would not change dies' );
    is( mode_of($real),                         oct 666,                                                          'and the file that the link names did not change' );
    is( mode_of($open),                         oct 777,                                                          'nor the directory that holds the link' );
};

subtest 'secure: owners, through stat_entry' => sub {
    my $mock = Test::MockModule->new('Path::Secure');
    my %owner;
    $mock->redefine(
        stat_entry => sub {
            my ($path) = @_;
            my @status = $stat_entry->($path);
            $status[4] = $owner{$path} if @status && exists $owner{$path};
            return @status;
        }
    );
    my ( $ws, $repo, $file ) = workspace('owned-ws');

    %owner = ( $repo => $> + 1 );
    is( dies { secure( $file, upto => $ws ) }, "secure cannot make $file safe: another account owns $repo\n", 'a directory that another account owns dies' );

  SKIP: {
        skip 'root can change the mode of what root owns', 1 if $> == 0;
        %owner = ( $repo => 0 );
        is( dies { secure( $file, upto => $ws ) }, "secure cannot make $file safe: $repo needs its mode changed, and only root can do that\n", 'a change to what root owns dies when the process is not root' );
    }
    is( [ map { mode_of($_) } $ws, $repo, $file ], [ oct 770, oct 775, oct 664 ], 'neither changed a mode' );
};

subtest 'secure: the changes, through change_mode' => sub {
    my $mock = Test::MockModule->new('Path::Secure');

    my ( $ws, $repo, $file ) = workspace('order-ws');

    # Each change, with the mode that the change before it had given by then.
    my ( @order, $last );
    $mock->redefine(
        change_mode => sub {
            my ( $mode, $path ) = @_;
            push @order, [ $path, defined $last ? mode_of($last) : () ];
            $last = $path;
            return $change_mode->( $mode, $path );
        }
    );
    secure( $file, upto => $ws );
    is( \@order, [ [$ws], [ $repo, oct 1770 ], [ $file, oct 1775 ] ], 'each parent has its new mode before its child changes' );

    my ( $fws, $frepo, $ffile ) = workspace('failing-ws');
    $mock->redefine(
        change_mode => sub {
            my ( $mode, $path ) = @_;

            # A chmod of nothing, which fails as a real one does and sets $!.
            return chmod $mode, "$base/bogus" if $path eq $ffile;
            return $change_mode->( $mode, $path );
        }
    );
    is( dies { secure( $ffile, upto => $fws ) }, "secure stopped: chmod $ffile: @{[ strerror(ENOENT) ]}; it had changed $fws, $frepo\n", 'a chmod that fails dies, and says what changed before it' );

    my ( $nws, $nrepo, $nfile ) = workspace('noop-ws');
    $mock->redefine( change_mode => sub { return 1 } );
    is( dies { secure( $nfile, upto => $nws ) }, "secure changed $nws, $nrepo, $nfile, but the group of $nws can write it\n", 'a path that is still exposed at the end dies, rather than return as if it were safe' );
};

subtest 'secure: an entry that changes under it, through stat_entry' => sub {
    my $mock = Test::MockModule->new('Path::Secure');
    my ( $ws, $repo, $file ) = workspace('race-ws');
    my $looks = 0;
    $mock->redefine(
        stat_entry => sub {
            my ($path) = @_;
            my @status = $stat_entry->($path);

            # The planning looks once, the check of the plan once more, and
            # the change once more: on that third look, it is another entry.
            $status[1]++ if $path eq $repo && ++$looks == 3;
            return @status;
        }
    );
    is( dies { secure( $file, upto => $ws ) },     "secure stopped: $repo changed while it worked; it had changed $ws\n", 'an entry that is not the one that it planned for stops it' );
    is( [ map { mode_of($_) } $ws, $repo, $file ], [ oct 1770, oct 775, oct 664 ],                                        'after the parent, and before the entry' );
};

done_testing;
