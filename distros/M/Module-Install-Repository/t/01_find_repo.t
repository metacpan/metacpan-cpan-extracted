use strict;
use warnings;
use Test::More tests => 2;

use Module::Install::Repository;

use File::Temp qw(tempdir);
use Path::Class;

sub fake_execute {
    my ($s) = @_;
    return {
        'hg paths' => "default = http://example.com/foo/bar/\n",
        'git remote show -n origin' => <<'END'
* remote origin
  URL: git@github.com:miyagawa/module-install-repository.git
  Remote branch merged with 'git pull' while on branch master
    master
  Tracked remote branch
    master
END
    }->{ $s };
}

sub test {
    my ($basename) = @_;

    my $dir = tempdir(CLEANUP => 1);
    dir("$dir/$basename")->mkpath;
    chdir($dir);

    return Module::Install::Repository::_find_repo(\&fake_execute);
}

is(test('.git'), 'git://github.com/miyagawa/module-install-repository.git', 'Git');
is(test('.hg'), 'http://example.com/foo/bar/', 'Mercurial');
