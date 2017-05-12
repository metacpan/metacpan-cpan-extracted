use Test::More;
use Plack::Test;
use Plack::Builder;
use HTTP::Request;
use Cwd qw(abs_path);

use Plack::App::Directory::Template;

my $cwd = abs_path();

my $app = builder {
    mount '/mnt/' => Plack::App::Directory::Template->new(
        root       => 't/dir',
        templates => \ do { local $/; <DATA> },
        filter       => sub { return $_[0] if $_[0]->{name} =~ /foo/; }
    );
    mount '/' => sub {}
};

test_psgi $app, sub {
    my $cb = shift;
    my $res = $cb->(HTTP::Request->new(GET => '/mnt/subdir/'));

    my $pathes = join "\n",
      "$cwd/t/dir",             # root
      "$cwd/t/dir/subdir",      # dir
      "/subdir/",               # path
      "/mnt/subdir/",           # urlpath
      '#foo.txt',               # file.name
      "/mnt/subdir/%23foo.txt", # file.url
    ;
    is $res->content, $pathes, 'pathes';
};

done_testing;

__DATA__
[% root %]
[% dir %]
[% path %]
[% urlpath %]
[% files.0.name %]
[% files.0.url -%]
