#!/usr/bin/env perl

use strict;
use warnings;
use Test2::V0;
use Future::AsyncAwait;
use IO::Async::Loop;

use lib 'lib';

use PAGI::Middleware::XSendfile;

my $loop = IO::Async::Loop->new;

sub run_async {
    my ($code) = @_;
    my $future = $code->();
    $loop->await($future);
}

# Helper to find header value
sub find_header {
    my ($headers, $name) = @_;
    for my $h (@$headers) {
        return $h->[1] if lc($h->[0]) eq lc($name);
    }
    return undef;
}

# =============================================================================
# Test: Basic X-Sendfile header for file responses
# =============================================================================

subtest 'X-Sendfile header added for file response' => sub {
    my $mw = PAGI::Middleware::XSendfile->new(type => 'X-Sendfile');

    my $app = async sub {
        my ($scope, $receive, $send) = @_;
        await $send->({
            type    => 'http.response.start',
            status  => 200,
            headers => [
                ['content-type', 'application/octet-stream'],
                ['content-disposition', 'attachment; filename="test.bin"'],
            ],
        });
        await $send->({
            type => 'http.response.body',
            file => '/var/www/files/test.bin',
        });
    };

    my $wrapped = $mw->wrap($app);

    my @sent;
    run_async(async sub {
        await $wrapped->(
            { type => 'http', path => '/download' },
            async sub { { type => 'http.disconnect' } },
            async sub { my ($event) = @_; push @sent, $event },
        );
    });

    is scalar(@sent), 2, 'two events sent';
    is $sent[0]{type}, 'http.response.start', 'first event is response start';
    is $sent[0]{status}, 200, 'status preserved';

    my $xsendfile = find_header($sent[0]{headers}, 'X-Sendfile');
    is $xsendfile, '/var/www/files/test.bin', 'X-Sendfile header set correctly';

    is $sent[1]{type}, 'http.response.body', 'second event is response body';
    is $sent[1]{body}, '', 'body is empty (proxy serves the file)';
};

subtest 'X-Accel-Redirect for Nginx' => sub {
    my $mw = PAGI::Middleware::XSendfile->new(
        type    => 'X-Accel-Redirect',
        mapping => { '/var/www/protected/' => '/internal/' },
    );

    my $app = async sub {
        my ($scope, $receive, $send) = @_;
        await $send->({
            type    => 'http.response.start',
            status  => 200,
            headers => [['content-type', 'video/mp4']],
        });
        await $send->({
            type => 'http.response.body',
            file => '/var/www/protected/videos/movie.mp4',
        });
    };

    my $wrapped = $mw->wrap($app);

    my @sent;
    run_async(async sub {
        await $wrapped->(
            { type => 'http', path => '/stream/movie' },
            async sub { { type => 'http.disconnect' } },
            async sub { my ($event) = @_; push @sent, $event },
        );
    });

    my $accel = find_header($sent[0]{headers}, 'X-Accel-Redirect');
    is $accel, '/internal/videos/movie.mp4', 'X-Accel-Redirect path mapped correctly';
};

subtest 'X-Lighttpd-Send-File for Lighttpd' => sub {
    my $mw = PAGI::Middleware::XSendfile->new(type => 'X-Lighttpd-Send-File');

    my $app = async sub {
        my ($scope, $receive, $send) = @_;
        await $send->({
            type    => 'http.response.start',
            status  => 200,
            headers => [],
        });
        await $send->({
            type => 'http.response.body',
            file => '/srv/files/document.pdf',
        });
    };

    my $wrapped = $mw->wrap($app);

    my @sent;
    run_async(async sub {
        await $wrapped->(
            { type => 'http', path => '/doc' },
            async sub { { type => 'http.disconnect' } },
            async sub { my ($event) = @_; push @sent, $event },
        );
    });

    my $lighttpd = find_header($sent[0]{headers}, 'X-Lighttpd-Send-File');
    is $lighttpd, '/srv/files/document.pdf', 'X-Lighttpd-Send-File header set';
};

# =============================================================================
# Test: Mapping configurations
# =============================================================================

subtest 'simple string prefix mapping' => sub {
    my $mw = PAGI::Middleware::XSendfile->new(
        type    => 'X-Accel-Redirect',
        mapping => '/protected',
    );

    my $app = async sub {
        my ($scope, $receive, $send) = @_;
        await $send->({
            type    => 'http.response.start',
            status  => 200,
            headers => [],
        });
        await $send->({
            type => 'http.response.body',
            file => '/var/www/files/doc.txt',
        });
    };

    my $wrapped = $mw->wrap($app);

    my @sent;
    run_async(async sub {
        await $wrapped->(
            { type => 'http', path => '/' },
            async sub { { type => 'http.disconnect' } },
            async sub { my ($event) = @_; push @sent, $event },
        );
    });

    my $accel = find_header($sent[0]{headers}, 'X-Accel-Redirect');
    is $accel, '/protected/var/www/files/doc.txt', 'prefix prepended to path';
};

subtest 'no mapping passes path through' => sub {
    my $mw = PAGI::Middleware::XSendfile->new(type => 'X-Sendfile');

    my $app = async sub {
        my ($scope, $receive, $send) = @_;
        await $send->({
            type    => 'http.response.start',
            status  => 200,
            headers => [],
        });
        await $send->({
            type => 'http.response.body',
            file => '/absolute/path/to/file.txt',
        });
    };

    my $wrapped = $mw->wrap($app);

    my @sent;
    run_async(async sub {
        await $wrapped->(
            { type => 'http', path => '/' },
            async sub { { type => 'http.disconnect' } },
            async sub { my ($event) = @_; push @sent, $event },
        );
    });

    my $xsendfile = find_header($sent[0]{headers}, 'X-Sendfile');
    is $xsendfile, '/absolute/path/to/file.txt', 'path unchanged without mapping';
};

# =============================================================================
# Test: Non-file responses pass through unchanged
# =============================================================================

subtest 'regular body response passes through' => sub {
    my $mw = PAGI::Middleware::XSendfile->new(type => 'X-Sendfile');

    my $app = async sub {
        my ($scope, $receive, $send) = @_;
        await $send->({
            type    => 'http.response.start',
            status  => 200,
            headers => [['content-type', 'text/plain']],
        });
        await $send->({
            type => 'http.response.body',
            body => 'Hello, World!',
        });
    };

    my $wrapped = $mw->wrap($app);

    my @sent;
    run_async(async sub {
        await $wrapped->(
            { type => 'http', path => '/' },
            async sub { { type => 'http.disconnect' } },
            async sub { my ($event) = @_; push @sent, $event },
        );
    });

    is scalar(@sent), 2, 'two events sent';

    # No X-Sendfile header
    my $xsendfile = find_header($sent[0]{headers}, 'X-Sendfile');
    is $xsendfile, undef, 'no X-Sendfile header for regular body';

    is $sent[1]{body}, 'Hello, World!', 'body passed through unchanged';
};

subtest 'streaming response passes through' => sub {
    my $mw = PAGI::Middleware::XSendfile->new(type => 'X-Sendfile');

    my $app = async sub {
        my ($scope, $receive, $send) = @_;
        await $send->({
            type    => 'http.response.start',
            status  => 200,
            headers => [],
        });
        await $send->({
            type => 'http.response.body',
            body => 'chunk1',
            more => 1,
        });
        await $send->({
            type => 'http.response.body',
            body => 'chunk2',
            more => 0,
        });
    };

    my $wrapped = $mw->wrap($app);

    my @sent;
    run_async(async sub {
        await $wrapped->(
            { type => 'http', path => '/' },
            async sub { { type => 'http.disconnect' } },
            async sub { my ($event) = @_; push @sent, $event },
        );
    });

    is scalar(@sent), 3, 'three events sent (start + 2 body chunks)';
    is $sent[1]{body}, 'chunk1', 'first chunk passed through';
    is $sent[2]{body}, 'chunk2', 'second chunk passed through';
};

# =============================================================================
# Test: Filehandle with path() method
# =============================================================================

subtest 'filehandle with path method works' => sub {
    my $mw = PAGI::Middleware::XSendfile->new(type => 'X-Sendfile');

    # Create a mock filehandle with path method
    my $mock_fh = bless {}, 'MockFHWithPath';
    {
        no strict 'refs';
        *{'MockFHWithPath::path'} = sub { '/mocked/path/file.bin' };
    }

    my $app = async sub {
        my ($scope, $receive, $send) = @_;
        await $send->({
            type    => 'http.response.start',
            status  => 200,
            headers => [],
        });
        await $send->({
            type => 'http.response.body',
            fh   => $mock_fh,
        });
    };

    my $wrapped = $mw->wrap($app);

    my @sent;
    run_async(async sub {
        await $wrapped->(
            { type => 'http', path => '/' },
            async sub { { type => 'http.disconnect' } },
            async sub { my ($event) = @_; push @sent, $event },
        );
    });

    my $xsendfile = find_header($sent[0]{headers}, 'X-Sendfile');
    is $xsendfile, '/mocked/path/file.bin', 'X-Sendfile from fh->path()';
    is $sent[1]{body}, '', 'body is empty';
};

subtest 'plain filehandle without path passes through' => sub {
    my $mw = PAGI::Middleware::XSendfile->new(type => 'X-Sendfile');

    # Use a plain unblessed reference (no path method)
    my $plain_fh = \*STDIN;  # Just for testing, won't actually read

    my $app = async sub {
        my ($scope, $receive, $send) = @_;
        await $send->({
            type    => 'http.response.start',
            status  => 200,
            headers => [],
        });
        await $send->({
            type => 'http.response.body',
            fh   => $plain_fh,
        });
    };

    my $wrapped = $mw->wrap($app);

    my @sent;
    run_async(async sub {
        await $wrapped->(
            { type => 'http', path => '/' },
            async sub { { type => 'http.disconnect' } },
            async sub { my ($event) = @_; push @sent, $event },
        );
    });

    # No X-Sendfile header - passes through
    my $xsendfile = find_header($sent[0]{headers}, 'X-Sendfile');
    is $xsendfile, undef, 'no X-Sendfile for plain fh without path method';

    # The fh should be passed through unchanged
    is $sent[1]{fh}, $plain_fh, 'fh passed through for normal handling';
};

# =============================================================================
# Test: Non-HTTP requests skip middleware
# =============================================================================

subtest 'websocket requests pass through' => sub {
    my $mw = PAGI::Middleware::XSendfile->new(type => 'X-Sendfile');

    my $app = async sub {
        my ($scope, $receive, $send) = @_;
        await $send->({
            type    => 'websocket.accept',
            headers => [],
        });
    };

    my $wrapped = $mw->wrap($app);

    my @sent;
    run_async(async sub {
        await $wrapped->(
            { type => 'websocket', path => '/ws' },
            async sub { { type => 'websocket.disconnect' } },
            async sub { my ($event) = @_; push @sent, $event },
        );
    });

    is $sent[0]{type}, 'websocket.accept', 'websocket event passed through';
};

# =============================================================================
# Test: Headers preserved
# =============================================================================

subtest 'original headers preserved' => sub {
    my $mw = PAGI::Middleware::XSendfile->new(type => 'X-Sendfile');

    my $app = async sub {
        my ($scope, $receive, $send) = @_;
        await $send->({
            type    => 'http.response.start',
            status  => 200,
            headers => [
                ['content-type', 'application/pdf'],
                ['content-disposition', 'attachment; filename="doc.pdf"'],
                ['cache-control', 'private'],
            ],
        });
        await $send->({
            type => 'http.response.body',
            file => '/docs/doc.pdf',
        });
    };

    my $wrapped = $mw->wrap($app);

    my @sent;
    run_async(async sub {
        await $wrapped->(
            { type => 'http', path => '/' },
            async sub { { type => 'http.disconnect' } },
            async sub { my ($event) = @_; push @sent, $event },
        );
    });

    my $ct = find_header($sent[0]{headers}, 'content-type');
    my $cd = find_header($sent[0]{headers}, 'content-disposition');
    my $cc = find_header($sent[0]{headers}, 'cache-control');
    my $xs = find_header($sent[0]{headers}, 'X-Sendfile');

    is $ct, 'application/pdf', 'content-type preserved';
    is $cd, 'attachment; filename="doc.pdf"', 'content-disposition preserved';
    is $cc, 'private', 'cache-control preserved';
    is $xs, '/docs/doc.pdf', 'X-Sendfile added';
};

# =============================================================================
# Test: Variation header
# =============================================================================

subtest 'variation header added when configured' => sub {
    my $mw = PAGI::Middleware::XSendfile->new(
        type      => 'X-Sendfile',
        variation => 'X-Sendfile',
    );

    my $app = async sub {
        my ($scope, $receive, $send) = @_;
        await $send->({
            type    => 'http.response.start',
            status  => 200,
            headers => [],
        });
        await $send->({
            type => 'http.response.body',
            file => '/path/to/file',
        });
    };

    my $wrapped = $mw->wrap($app);

    my @sent;
    run_async(async sub {
        await $wrapped->(
            { type => 'http', path => '/' },
            async sub { { type => 'http.disconnect' } },
            async sub { my ($event) = @_; push @sent, $event },
        );
    });

    my $vary = find_header($sent[0]{headers}, 'Vary');
    is $vary, 'X-Sendfile', 'Vary header added';
};

# =============================================================================
# Test: Partial content (Range requests) bypass XSendfile
# =============================================================================

subtest 'partial content with offset bypasses XSendfile' => sub {
    my $mw = PAGI::Middleware::XSendfile->new(type => 'X-Sendfile');

    my $app = async sub {
        my ($scope, $receive, $send) = @_;
        await $send->({
            type    => 'http.response.start',
            status  => 206,
            headers => [
                ['content-type', 'application/octet-stream'],
                ['content-range', 'bytes 0-99/1000'],
            ],
        });
        await $send->({
            type   => 'http.response.body',
            file   => '/var/www/files/large.bin',
            offset => 0,
            length => 100,
        });
    };

    my $wrapped = $mw->wrap($app);

    my @sent;
    run_async(async sub {
        await $wrapped->(
            { type => 'http', path => '/download' },
            async sub { { type => 'http.disconnect' } },
            async sub { my ($event) = @_; push @sent, $event },
        );
    });

    # No X-Sendfile header - partial content passed through
    my $xsendfile = find_header($sent[0]{headers}, 'X-Sendfile');
    is $xsendfile, undef, 'no X-Sendfile header for partial content';

    # File response passed through for server to handle
    is $sent[1]{file}, '/var/www/files/large.bin', 'file passed through';
    is $sent[1]{offset}, 0, 'offset preserved';
    is $sent[1]{length}, 100, 'length preserved';
};

subtest 'partial content with length only bypasses XSendfile' => sub {
    my $mw = PAGI::Middleware::XSendfile->new(type => 'X-Sendfile');

    my $app = async sub {
        my ($scope, $receive, $send) = @_;
        await $send->({
            type    => 'http.response.start',
            status  => 200,
            headers => [],
        });
        await $send->({
            type   => 'http.response.body',
            file   => '/var/www/files/file.bin',
            length => 500,  # Only first 500 bytes
        });
    };

    my $wrapped = $mw->wrap($app);

    my @sent;
    run_async(async sub {
        await $wrapped->(
            { type => 'http', path => '/' },
            async sub { { type => 'http.disconnect' } },
            async sub { my ($event) = @_; push @sent, $event },
        );
    });

    my $xsendfile = find_header($sent[0]{headers}, 'X-Sendfile');
    is $xsendfile, undef, 'no X-Sendfile for length-limited response';
    is $sent[1]{length}, 500, 'length preserved for server handling';
};

# =============================================================================
# Test: Invalid configuration
# =============================================================================

subtest 'dies without type parameter' => sub {
    like(
        dies { PAGI::Middleware::XSendfile->new() },
        qr/requires 'type' parameter/,
        'dies without type'
    );
};

subtest 'dies with invalid type' => sub {
    like(
        dies { PAGI::Middleware::XSendfile->new(type => 'X-Invalid') },
        qr/Invalid XSendfile type/,
        'dies with invalid type'
    );
};

done_testing;
