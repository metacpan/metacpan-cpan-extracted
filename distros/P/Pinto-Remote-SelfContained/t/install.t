#!perl

use v5.10;
use strict;
use warnings;

use Capture::Tiny qw(capture_stderr capture_stdout);
use Test::Deep qw(cmp_deeply re);
use Test::Fatal qw(exception);
use Test::More;
use Test::Warnings qw(had_no_warnings :no_end_test);

use Path::Tiny qw(path);
use lib path(__FILE__)->sibling('lib')->stringify;

use T::Chrome;
use T::HTTPTiny;
use T::Install;

sub action {
    my ($args, %attrs) = @_;
    return T::Install->new({
        username => 'fred',
        password => undef,
        root => 'http://example.com',
        chrome => T::Chrome->new,
        name => 'install',
        args => $args,
        %attrs,
    });
}

subtest 'default cpanm_exe' => sub {
    local $ENV{PINTO_HOME};
    delete $ENV{PINTO_HOME};
    my $action = Pinto::Remote::SelfContained::Action::Install->new(
        username => 'fred',
        password => undef,
        root => 'http://example.com',
        chrome => T::Chrome->new,
        name => 'install',
        args => {},
    );

    my $cpanm;
    my $exception = exception { capture_stderr { $cpanm = $action->cpanm_exe } };
    return plan skip_all => 'No cpanm installed locally'
        if defined $exception
        && $exception =~ /^Could not learn version of cpanm|^Your cpanm \([0-9.]+\) is too old/;
    is($exception, undef, 'no exception finding cpanm');
    is($cpanm, 'cpanm', 'found cpanm correctly');
};

subtest 'mirror_uri' => sub {
    is( action({})->mirror_uri, 'http://example.com',
        'mirror_uri for empty stack' );

    is( action({ stack => 'foo' })->mirror_uri, 'http://example.com/stacks/foo',
        'mirror_uri for stack foo' );
};

subtest 'install without pull', sub {
    my $response = "HTTP/1.0 200 OK\r\nContent-type: application/vnd.pinto.v1+text\r\n\r\n## Status: ok\n";
    my $chrome = T::Chrome->new;
    my $httptiny = T::HTTPTiny->new([$response]);
    my $action = action({}, httptiny => $httptiny, chrome => $chrome);

    my @cpanm_args = unpack '(Z*)*', capture_stdout { $action->execute };

    is_deeply($httptiny->requests, [], 'no requests made')
        or diag(explain($httptiny->requests));
    is_deeply(\@cpanm_args, ['--mirror', 'http://example.com', '--mirror-only'],
              'cpanm arguments')
        or diag(explain(\@cpanm_args));
};

subtest 'install with pull', sub {
    my $response = "HTTP/1.0 200 OK\r\nContent-type: application/vnd.pinto.v1+text\r\n\r\n## Status: ok\n";
    my $chrome = T::Chrome->new(verbose => 3);
    my $httptiny = T::HTTPTiny->new([$response]);
    my $action = action({ do_pull => 1 }, httptiny => $httptiny, chrome => $chrome);
    my $cpanm = join ' ', $action->cpanm_exe;

    my @cpanm_args = unpack '(Z*)*', capture_stdout { $action->execute };

    is(scalar @{ $httptiny->requests }, 1, 'made one request')
        and is($httptiny->requests->[0]{uri}, '/action/pull', 'with correct uri');
    is(${ $chrome->stdout_buf }, '', 'stdout');
    is(${ $chrome->stderr_buf }, "Running: $cpanm --mirror http://example.com --mirror-only\n",
        'stderr');
    is_deeply(\@cpanm_args, ['--mirror', 'http://example.com', '--mirror-only'],
              'cpanm arguments')
        or diag(explain(\@cpanm_args));
};

subtest 'install with pull and password', sub {
    my $response = "HTTP/1.0 200 OK\r\nContent-type: application/vnd.pinto.v1+text\r\n\r\n## Status: ok\n";
    my $chrome = T::Chrome->new;
    my $httptiny = T::HTTPTiny->new([$response]);
    my $action = action({ do_pull => 1 }, httptiny => $httptiny, chrome => $chrome, password => 's3kr1t');
    my $cpanm = join ' ', $action->cpanm_exe;

    my @cpanm_args = unpack '(Z*)*', capture_stdout { $action->execute };

    cmp_deeply($httptiny->requests, [{
        body => re(qr/name="chrome" .* name="pinto" .* name="action"/xms),
        headers => {
            'accept' => 'application/vnd.pinto.v1+text',
            'authorization' => 'Basic ZnJlZDpzM2tyMXQ=',
            'content-length' => re(qr/^(?:0|[1-9][0-9]*)\z/),
            'content-type' => re(qr{^multipart/form-data; boundary=[a-zA-Z0-9]+\z}),
            'host' => 'example.com',
            'user-agent' => 'T-HTTPTiny/0.900',
        },
        host => 'example.com',
        host_port => 'example.com',
        method => 'POST',
        port => 80,
        scheme => 'http',
        uri => '/action/pull',
    }], 'one request')
        or diag(explain($httptiny->requests));
    is(${ $chrome->stdout_buf }, '', 'stdout');
    is(${ $chrome->stderr_buf }, '', 'stderr');
    is_deeply(\@cpanm_args, ['--mirror', 'http://fred:s3kr1t@example.com', '--mirror-only'],
              'cpanm arguments')
        or diag(explain(\@cpanm_args));
};

subtest 'install with --reinstall and password', sub {
    my $response = "HTTP/1.0 200 OK\r\nContent-type: application/vnd.pinto.v1+text\r\n\r\n## Status: ok\n";
    my $chrome = T::Chrome->new(verbose => 3);
    my $httptiny = T::HTTPTiny->new([$response]);
    my $action = action(
        { cpanm_options => { reinstall => '' } }, 
        password => 's3kr1t',
        httptiny => $httptiny,
        chrome => $chrome,
    );
    my $cpanm = join ' ', $action->cpanm_exe;

    my @cpanm_args = unpack '(Z*)*', capture_stdout { $action->execute };

    is_deeply($httptiny->requests, [], 'no requests made')
        or diag(explain($httptiny->requests));
    is(${ $chrome->stdout_buf }, '', 'stdout');
    is(${ $chrome->stderr_buf }, "Running: $cpanm --mirror http://fred:*password*\@example.com --mirror-only --reinstall\n",
        'stderr');
    is_deeply(\@cpanm_args, ['--mirror', 'http://fred:s3kr1t@example.com', '--mirror-only', '--reinstall'],
              'cpanm arguments')
        or diag(explain(\@cpanm_args));
};

had_no_warnings();
done_testing();
