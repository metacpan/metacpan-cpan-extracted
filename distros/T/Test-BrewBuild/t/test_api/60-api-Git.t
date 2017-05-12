#!/usr/bin/perl
use strict;
use warnings;

use Cwd;
use File::Path qw(remove_tree);
use Test::BrewBuild::Git;
use Test::More;

if (! $ENV{BBDEV_TESTING}){
    plan skip_all => "developer tests only";
    exit;
}

my $mod = 'Test::BrewBuild::Git';
my $wdir = "t/repo";
my $cwd = getcwd();

mkdir $wdir or die $! if ! -d $wdir;

{ #new
    my $git = $mod->new;
    is (ref $git, $mod, "obj is a $mod");
}
{ # link
    my $git = $mod->new;
    my $link = $git->link;

    like (
        $link,
        qr{github.com/stevieb9/test-brewbuild},
        "link is correct",
    );
}
{ # clone & name & pull

    my $git = $mod->new;
    my $link = $git->link;
    my $name = $git->name($link);

    chdir $wdir or die $!;

    is ($name, 'test-brewbuild', "name of repo dir is ok");

    my $ret = $git->clone($link);
    like ($ret, qr/Cloning into/, "clone() ok");
    is (-d $name, 1, "repo dir created ok via clone");

    chdir $name or die $!;
    $ret = $git->pull;
    print $ret;
}
{ # _separate_url

    my $git = $mod->new;

    my @res;

    @res = $git->_separate_url;

    is $res[0], 'stevieb9', "user portion of _separate_url ok w/no params";
    like $res[1], qr/test-brewbuild/, "repo portion of _separate_url ok w/no params";

    @res = $git->_separate_url('https://github.com/stevieb9/test-brewbuild');

    is $res[0], 'stevieb9', "user portion of _separate_url ok with repo param";
    like $res[1], qr/test-brewbuild/, "repo portion of _separate_url ok with repo";
}
{ # revision

    my $git = $mod->new;
    my $csum;

    # local
    $csum = $git->revision;
    is length($csum), 40, "commit sum pans out ok for local";

    # remote w/o repo
    my $ok = eval {
        $csum = $git->revision(remote => 1);
        1;
    };
    is $ok, undef, "revision() with remote param dies without repo param";
    like $@, qr/requires/, "...with sane error msg";
    undef $@;


    # remote with repo
    $csum = $git->revision(repo => 'https://github.com/stevieb9/test-brewbuild', remote => 1);
    is length($csum), 40, "commit sum pans out ok for remote with repo param";
    
    # local with repo url
    $csum = $git->revision(repo => 'https://github.com/stevieb9/test-brewbuild');
    is length($csum), 40, "commit sum pans out ok for local with repo param";

    # remote with repo url
    $csum = $git->revision(remote => 1, repo => 'https://github.com/stevieb9/test-brewbuild');
    is length($csum), 40, "commit sum pans out ok for remote with repo param";
}

chdir $cwd or die $!;
remove_tree $wdir or die $!;
is (-d $wdir, undef, "removed work dir ok");

done_testing();

