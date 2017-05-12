#!/usr/bin/perl
$ENV{LC_ALL} = 'C';

use Test::More;
use SVN::Mirror;
use File::Path;
use URI::file;
use strict;

plan skip_all => "can't find svnadmin"
    unless `svnadmin --version` =~ /version/;

plan tests => 58;

sub setup_sync {
    my $skip_to = shift;

    my $repospath = "t/repos";
    rmtree ([$repospath]) if -d $repospath;
    $ENV{SVNFSTYPE} ||= (($SVN::Core::VERSION =~ /^1\.0/) ? 'bdb' : 'fsfs');

    my $repos = SVN::Repos::create($repospath, undef, undef, undef,
				   {'fs-type' => $ENV{SVNFSTYPE}})
        or die "failed to create repository at $repospath";

    my $uri = URI::file->new_abs( $repospath ) ;

    `svn mkdir -m 'init' $uri/source`;
    `svnadmin load --parent-dir source $repospath < t/test_repo.dump`;

    my $m = SVN::Mirror->new(target_path => '/fullcopy', repos => $repos,
			     source => "$uri/source", skip_to => $skip_to);
    $m->init ();

    return $m;
}

sub test_sync {
    my ($skip_to, $torev, $match1, $match2, $last_rev) = @_;

    my $m = setup_sync($skip_to);
    $m->run ($torev);

    if (defined $match1) {
        is (scalar $m->find_remote_rev ($match1->[0]), $match1->[1],
	    'rev ' . $match1->[0] . ' mirrored from rev ' . $match1->[1]);
    }
    if (defined $match2) {
        is (scalar $m->find_remote_rev ($match2->[0]), $match2->[1],
	    'rev ' . $match2->[0] . ' mirrored from rev ' . $match2->[1]);
    }

    my $last_plus_one = $last_rev + 1;
    eval { $m->find_remote_rev ($last_plus_one) };
    like ($@, qr/^Invalid filesystem revision number: No such revision $last_plus_one/,
	  'last revision is ' . $last_rev);
}

sub test_invalid_sync {
    my ($skip_to, $torev) = @_;

    my $m = setup_sync($skip_to);
    eval { $m->run ($torev) };
    like ($@, qr/^Invalid filesystem revision number: No such revision 31/,
	  'last revision is 30');
}

my @sync_tests = (
#    skip_to /  to_rev  
    [undef,    undef,    [31,  1], [59, 29], 59],
    [1,        undef,    [31,  1], [59, 29], 59],
    [2,        undef,    [31,  2], [58, 29], 58],
    ['HEAD',   undef,    [31, 29], undef,    31],
    ['HEAD-1', undef,    [31, 28], [32, 29], 32],
    [undef,    1,        [31,  1], undef,    31],
    [undef,    2,        [31,  1], [32,  2], 32],
    [undef,    'HEAD',   [31,  1], [59, 29], 59],
    [undef,    'HEAD-1', [31,  1], [59, 29], 59],
    [undef,    'HEAD-2', [31,  1], [58, 28], 58],
    [1,        'HEAD',   [31,  1], [59, 29], 59],
    [1,        'HEAD-1', [31,  1], [58, 28], 58],
    [1,        1,        [31,  1], undef,    31],
    ['HEAD',   'HEAD',   [31, 29], undef,    31],
    [2,        'HEAD',   [31,  2], [58, 29], 58],
    [2,        'HEAD-1', [31,  2], [57, 28], 57],
    ['HEAD-5', 'HEAD',   [31, 24], [36, 29], 36],
    ['HEAD-5', 'HEAD-2', [31, 24], [34, 27], 34],

    ['HEAD',   1,        undef,    undef,    30],
    [31,       undef,    undef,    undef,    30],
    [31,       1,        undef,    undef,    30],
    [31,       'HEAD',   undef,    undef,    30],
);

my @invalid_sync_tests = (
    [undef, 31],
    [1,     31],
    [31,    31],
    [31,    32],
);

test_sync(@$_) for (@sync_tests);
test_invalid_sync(@$_) for (@invalid_sync_tests);
