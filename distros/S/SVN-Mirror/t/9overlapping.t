#!/usr/bin/perl
use Test::More;
use SVN::Mirror;
use File::Path;
use URI::file;
use strict;

plan skip_all => "can't find svnadmin"
    unless `svnadmin --version` =~ /version/;

plan tests => 11;
my $repospath = "t/repos";

rmtree ([$repospath]) if -d $repospath;
$ENV{SVNFSTYPE} ||= (($SVN::Core::VERSION =~ /^1\.0/) ? 'bdb' : 'fsfs');

my $repos = SVN::Repos::create($repospath, undef, undef, undef,
			       {'fs-type' => $ENV{SVNFSTYPE}})
    or die "failed to create repository at $repospath";

my $uri = URI::file->new_abs( $repospath ) ;

`svn mkdir -m 'init' $uri/source`;
`svnadmin load --parent-dir source $repospath < t/test_repo.dump`;


my @tests = (
    [[ '/source/deep' ],
     [ '/source/deep', '/source/deep' ],
     [ '/source/deep/more_deep', '/source/deep' ],
     [ '/source', '/source/deep' ],
     [ '/source/dir']],
    [[ '/' ],
     [ '/', '/' ],
     [ '/source', '/' ]],
    [[ '' ],
     [ '', '' ],
     [ '/source', '' ]],
);

my $test = 1;
for (@tests) {
    my @mirrors;

    for (@$_) {
        my $m = SVN::Mirror->new(target_path => "/overlapping$test", repos => $repos,
				 source => $uri . $_->[0]);
        eval { $m->init () };
        if (defined $_->[1]) {
            like ($@, qr/^Mirroring overlapping paths not supported/,
            	  "Can't mirror overlapping path ('$_->[0]' overlaps with '$_->[1]')");
        } else {
            is ($@, '', "initialised mirror '$_->[0]' -> /overlapping$test successfully; no overlap");
        }

        $test++;
        push @mirrors, $m;
    }

    $_->delete for (@mirrors);
}

