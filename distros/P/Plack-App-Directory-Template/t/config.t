use Test::More;
use Plack::Test;
use HTTP::Request;
use Plack::Builder;

use Plack::App::Directory::Template;

my $app = Plack::App::Directory::Template->new(
    root   => 't/dir/subdir',
    filter => sub { $_[0]->name =~ /foo/ ? $_[0] : () },
    templates    => '/dev/null',
    INCLUDE_PATH => 't/templates',
    VARIABLES    => { x => 42 },
    PRE_PROCESS  => 'header.tt',
    PRE_CHOMP    => 1,
);

test_psgi $app, sub {
    my $cb = shift;
    
    my $res = $cb->(HTTP::Request->new(GET => '/'));
    is $res->code, 200, 'ok';
    is $res->content, "42:\n#foo.txt\n", 'config';
};

$app->{PROCESS} = 'index2.html';
$app->prepare_app();

test_psgi $app, sub {
    my $cb = shift;
    my $res = $cb->(HTTP::Request->new(GET => '/'));
    is $res->content, "file error - index2.html: not found", 'PROCESS option';
};

done_testing;
