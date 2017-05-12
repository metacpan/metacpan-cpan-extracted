use HTTP::Request::Common;
use Plack::Builder;
use Plack::Test;
use Test::More;
use Test::Git;
use File::Slurp qw(write_file);

has_git();
my $r           = test_repository(temp => [ CLEANUP => 1 ]);
my $git_dir     = $r->work_tree;
my $file_name   = 'readme.txt';

write_file(File::Spec->catfile( $git_dir, $file_name ), << 'TXT' );
foo bar
TXT
$r->run( add => $file_name );
$r->run( commit => '-m', 'initial commit' );

my $body = ['<div>FooBar</div>'];
 
my $app = sub {
    my $env = shift;
    [200, ['Content-Type', 'text/html', 'Content-Length', length(join '', $body)], $body];
};
 
$app = builder {
    enable "Plack::Middleware::GitRevisionInfo", path => $r->git_dir;
    $app;
};

test_psgi $app, sub {
    my $cb = shift;
 
    my $res = $cb->(GET '/');
    is $res->code, 200;
    like $res->content, qr#<div>FooBar</div><!-- Revision:.*Date.*-->#;
};

$app = builder {
    enable "Plack::Middleware::GitRevisionInfo";
    return sub {
        my $env = shift;
        [200, ['Content-Type', 'text/html', 'Content-Length', length(join '', $body)], $body];
    }
};

test_psgi $app, sub {
    my $cb = shift;
 
    my $res = $cb->(GET '/');
    is $res->code, 200;
    is $res->content, '<div>FooBar</div>';
};

done_testing;
