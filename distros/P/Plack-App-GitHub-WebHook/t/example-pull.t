use strict;
use warnings;
use Test::More;
use Plack::Test;
use Plack::Util;
use HTTP::Request::Common;
use File::Temp 'tempdir';
use Cwd;
use Plack::App::GitHub::WebHook;

if ( ! eval { require Git::Repository; 1; } ) {
    plan(skip_all => 'Git::Repository required for this test');
    goto SKIP;
} elsif( !$ENV{RELEASE_TESTING} ) {
    plan(skip_all => 'skip test for release testing');
    goto SKIP;
}

my $work_tree = tempdir(CLEANUP => 1);

my $app = Plack::App::GitHub::WebHook->new(
    safe => 1,
    access => [],
    hook => [
        sub { $_[0]->{ref} eq 'refs/heads/master' },
        sub {
            unless( -d "$work_tree/.git") {
                my $origin = $_[0]->{repository}->{clone_url};
                Git::Repository->run( 'clone', $origin, $work_tree );
            }
            Git::Repository->new( work_tree => $work_tree )
                           ->run(qw(pull origin master));
        }
    ],
)->to_app;

test_psgi $app, sub {
    my $cb = shift;
    my $payload = <<JSON;
{
    "ref":"refs/heads/master",
    "repository": {
        "clone_url":"https://github.com/nichtich/Plack-App-GitHub-WebHook.git"
    }
}
JSON
    my $res = $cb->(POST '/', Content => $payload);

    is $res->code, 200;
    ok -d "$work_tree/.git", "cloned repository";
};

SKIP:
done_testing;
