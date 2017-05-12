use strict;
use Test::More;

use File::Which qw(which);
plan skip_all => 'could not find git' unless which('git');

use File::Spec::Functions qw(:ALL);
use File::Temp qw(tempdir);
use Plack::App::GitSmartHttp;

subtest "has root" => sub {
    my $root = tempdir;
    my $dir = catdir( $root, 'foo' );
    mkdir $dir;
    my $gsh = Plack::App::GitSmartHttp->new( root => $root );
    is( $gsh->get_git_repo_dir('foo'), $dir );
};

subtest "no root" => sub {
    my $dir = catdir( '.', 'foo' );
    mkdir $dir;
    my $gsh = Plack::App::GitSmartHttp->new();
    is( $gsh->get_git_repo_dir('foo'), rel2abs($dir) );
    rmdir $dir;
};

subtest "dir not found" => sub {
    my $root = tempdir;
    my $gsh = Plack::App::GitSmartHttp->new( root => $root );
    is( $gsh->get_git_repo_dir('foo'), undef );
};

done_testing;
