use warnings;
use strict;
use Capture::Tiny qw(capture);
use Env qw($PLACK_MW_DEBUG_REFCOUNTS_ON_CLEANUP);
use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;
use Test::More;

our $psgix_cleanup = 0;
my $app = sub {
    my $env = shift;
    $env->{'psgix.cleanup'} = $psgix_cleanup;
    return [
        200, [ 'Content-Type' => 'text/html' ], ['<body>Hello World</body>']
    ];
};
$app = builder {
    enable 'Debug', panels => [qw(RefCounts)];
    $app;
};
test_psgi $app, sub {
    my $cb  = shift;
    my ($out, $err, $res) = capture { $cb->(GET '/') };
    is   $out, '', "middleware adds nothing to STDOUT";
    is   $err, '', "middleware adds nothing to STDERR (first time)";
    is $res->code, 200, 'response status 200';
    my $html = $res->content;
    like $html, qr/This was the first load/, "HTML indicates first time";
    unlike $html,
        qr!Now</th>!,
        "HTML does not contain ref counts the first time";

    ($out, $err, $res) = capture { $cb->(GET '/') };
    is   $out, '', "middleware adds nothing to STDOUT";
    isnt $err, '', "middleware debugs to STDERR";
    is $res->code, 200, 'response status 200';
    $html = $res->content;
    like $html,
        qr!Now</th>!,
        "HTML contains ref counts panel";

    # TODO would be nice to test behavior when nothing changes

    {
        local $psgix_cleanup = 1;
        unlike $html,
               qr/\$PLACK_MW_DEBUG_REFCOUNTS_ON_CLEANUP is true/,
               'psgix.cleanup not used by default';
    }

    {
        local $PLACK_MW_DEBUG_REFCOUNTS_ON_CLEANUP = 1;
        my ($out, $err, $res) = capture { $cb->(GET '/') };
        unlike $res->content,
               qr/\$PLACK_MW_DEBUG_REFCOUNTS_ON_CLEANUP is true/,
               'psgix.cleanup needed for PLACK_MW_DEBUG_REFCOUNTS_ON_CLEANUP';
    }

    {
        local $PLACK_MW_DEBUG_REFCOUNTS_ON_CLEANUP = 1;
        local $psgix_cleanup = 1;
        my ($out, $err, $res) = capture { $cb->(GET '/') };
        like $res->content,
               qr/\$PLACK_MW_DEBUG_REFCOUNTS_ON_CLEANUP is true/,
               'psgix.cleanup needed for PLACK_MW_DEBUG_REFCOUNTS_ON_CLEANUP';
        # sadly the test framework doesn't actually have cleanup handlers
        # so we can't show that we're still outputting to STDERR
    }
};
done_testing;
