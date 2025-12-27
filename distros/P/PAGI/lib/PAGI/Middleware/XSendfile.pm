package PAGI::Middleware::XSendfile;

use strict;
use warnings;
use parent 'PAGI::Middleware';
use Future::AsyncAwait;
use Scalar::Util 'blessed';

=head1 NAME

PAGI::Middleware::XSendfile - Delegate file serving to reverse proxy

=head1 SYNOPSIS

    use PAGI::Middleware::Builder;

    # For Nginx (X-Accel-Redirect)
    my $app = builder {
        enable 'XSendfile',
            type    => 'X-Accel-Redirect',
            mapping => '/protected/files/';  # URL prefix for internal location
        $my_app;
    };

    # For Apache (mod_xsendfile)
    my $app = builder {
        enable 'XSendfile',
            type => 'X-Sendfile';
        $my_app;
    };

    # For Lighttpd
    my $app = builder {
        enable 'XSendfile',
            type => 'X-Lighttpd-Send-File';
        $my_app;
    };

=head1 DESCRIPTION

PAGI::Middleware::XSendfile intercepts file responses and replaces them with
a special header that tells the reverse proxy (Nginx, Apache, Lighttpd) to
serve the file directly. This is the recommended approach for serving large
files in production, as it:

=over 4

=item * Frees up your application worker immediately

=item * Uses the reverse proxy's optimized sendfile implementation

=item * Supports all the proxy's features (caching, range requests, etc.)

=back

=head2 How It Works

When your application sends a file response:

    await $send->({
        type => 'http.response.body',
        file => '/var/www/files/large.bin',
    });

This middleware intercepts it and instead sends:

    # Headers include: X-Accel-Redirect: /protected/files/large.bin
    # Body is empty - proxy serves the file

=head1 REVERSE PROXY CONFIGURATION

=head2 Nginx

Configure an internal location that maps to your files:

    location /protected/files/ {
        internal;
        alias /var/www/files/;
    }

Then use:

    enable 'XSendfile',
        type    => 'X-Accel-Redirect',
        mapping => { '/var/www/files/' => '/protected/files/' };

=head2 Apache

Enable mod_xsendfile and allow sending from your directory:

    XSendFile On
    XSendFilePath /var/www/files

Then use:

    enable 'XSendfile', type => 'X-Sendfile';

=head2 Lighttpd

Enable mod_fastcgi with C<x-sendfile> option:

    fastcgi.server = (
        "/" => ((
            "socket" => "/tmp/app.sock",
            "x-sendfile" => "enable"
        ))
    )

Then use:

    enable 'XSendfile', type => 'X-Lighttpd-Send-File';

=head1 CONFIGURATION

=over 4

=item * type (required)

The header type to use. One of:

    X-Accel-Redirect     - Nginx
    X-Sendfile           - Apache mod_xsendfile
    X-Lighttpd-Send-File - Lighttpd

=item * mapping (for X-Accel-Redirect)

Path mapping from filesystem paths to Nginx internal URLs. Can be:

A string prefix (simple case):

    mapping => '/protected/'
    # /var/www/files/foo.txt => /protected/var/www/files/foo.txt

A hashref for path translation:

    mapping => { '/var/www/files/' => '/protected/' }
    # /var/www/files/foo.txt => /protected/foo.txt

=item * variation (optional)

Additional string appended to Vary header to prevent caching issues.

=back

=head1 RANGE REQUESTS / PARTIAL CONTENT

B<For best results with XSendfile, disable range handling in your app.>

When using XSendfile with a reverse proxy, you should disable Range request
handling in your file-serving app (L<PAGI::App::File> or L<PAGI::Middleware::Static>)
and let the proxy handle Range requests natively:

    use PAGI::Middleware::Builder;
    use PAGI::App::File;

    my $app = builder {
        enable 'XSendfile',
            type    => 'X-Accel-Redirect',
            mapping => { '/var/www/files/' => '/protected/' };

        PAGI::App::File->new(
            root          => '/var/www/files',
            handle_ranges => 0,  # Let nginx handle Range requests
        )->to_app;
    };

With C<handle_ranges =E<gt> 0>:

=over 4

=item * Your app always sends full file paths via X-Sendfile

=item * The proxy receives Range headers directly from clients

=item * The proxy handles Range requests using its optimized sendfile

=back

This is more efficient than handling ranges in Perl.

=head2 Why Partial Responses Bypass XSendfile

If your app does process Range requests (the default behavior), it sends
file responses with C<offset> and C<length>. This middleware will pass
such responses through unchanged because reverse proxies don't support
byte range parameters in X-Sendfile headers:

    # This will use X-Sendfile (full file)
    await $send->({
        type => 'http.response.body',
        file => '/path/to/file.bin',
    });

    # This will bypass X-Sendfile (partial content)
    await $send->({
        type   => 'http.response.body',
        file   => '/path/to/file.bin',
        offset => 1000,
        length => 500,
    });

The recommended approach is to set C<handle_ranges =E<gt> 0> so your app
never produces partial responses, and let the proxy handle Range requests.

=head1 FILEHANDLE SUPPORT

This middleware supports two types of file responses:

=head2 File Path (Recommended)

    await $send->({
        type => 'http.response.body',
        file => '/path/to/file.bin',
    });

This always works - the path is used directly.

=head2 Filehandle with path() Method

    use IO::File::WithPath;  # or similar
    my $fh = IO::File::WithPath->new('/path/to/file.bin', 'r');

    await $send->({
        type => 'http.response.body',
        fh   => $fh,
    });

For filehandle responses, the middleware will only intercept if the
filehandle object has a C<path()> method that returns the filesystem path.
This is compatible with:

=over 4

=item * L<IO::File::WithPath>

=item * L<Plack::Util/set_io_path>

=item * Any blessed filehandle with a C<path()> method

=back

B<Plain filehandles without a path() method will be served normally>
(not via X-Sendfile). If you need X-Sendfile support for filehandles,
add a C<path> method to your IO object:

    # Simple approach: bless and add path method
    sub make_sendfile_fh {
        my ($path) = @_;
        open my $fh, '<', $path or die $!;
        bless $fh, 'My::FH::WithPath';
        return $fh;
    }

    package My::FH::WithPath;
    sub path { ${*{$_[0]}}{path} }  # or store path however you prefer

=cut

my %VALID_TYPES = (
    'X-Accel-Redirect'     => 1,
    'X-Sendfile'           => 1,
    'X-Lighttpd-Send-File' => 1,
);

sub _init {
    my ($self, $config) = @_;

    my $type = $config->{type}
        or die "XSendfile middleware requires 'type' parameter";

    die "Invalid XSendfile type '$type'. Must be one of: "
        . join(', ', sort keys %VALID_TYPES)
        unless $VALID_TYPES{$type};

    $self->{type}      = $type;
    $self->{mapping}   = $config->{mapping};
    $self->{variation} = $config->{variation};
}

sub wrap {
    my ($self, $app) = @_;

    return async sub {
        my ($scope, $receive, $send) = @_;

        # Only handle HTTP requests
        if ($scope->{type} ne 'http') {
            await $app->($scope, $receive, $send);
            return;
        }

        my $pending_start;

        my $wrapped_send = async sub {
            my ($event) = @_;
            my $type = $event->{type};

            if ($type eq 'http.response.start') {
                # Buffer the start event - we might need to modify headers
                $pending_start = $event;
                return;
            }

            if ($type eq 'http.response.body') {
                my $path = $self->_extract_path($event);

                # Skip XSendfile for partial content (offset/length) - proxies don't support it
                my $is_partial = defined $event->{offset} || defined $event->{length};

                if (defined $path && !$is_partial) {
                    # We have a full file path - use X-Sendfile
                    my $mapped_path = $self->_map_path($path);
                    my @headers = @{$pending_start->{headers} // []};

                    # Add the X-Sendfile header
                    push @headers, [$self->{type}, $mapped_path];

                    # Add Vary header if configured
                    if ($self->{variation}) {
                        push @headers, ['Vary', $self->{variation}];
                    }

                    # Send response with empty body
                    await $send->({
                        type    => 'http.response.start',
                        status  => $pending_start->{status},
                        headers => \@headers,
                    });
                    await $send->({
                        type => 'http.response.body',
                        body => '',
                    });

                    $pending_start = undef;
                    return;
                }
            }

            # Not a file response, or no path available - pass through
            if ($pending_start) {
                await $send->($pending_start);
                $pending_start = undef;
            }
            await $send->($event);
        };

        await $app->($scope, $receive, $wrapped_send);

        # Flush any pending start that wasn't followed by a body
        if ($pending_start) {
            await $send->($pending_start);
        }
    };
}

sub _extract_path {
    my ($self, $event) = @_;

    # Direct file path - always works
    return $event->{file} if defined $event->{file};

    # Filehandle - only if it has a path() method
    if (my $fh = $event->{fh}) {
        if (blessed($fh) && $fh->can('path')) {
            my $path = $fh->path;
            return $path if defined $path && length $path;
        }
    }

    return undef;
}

sub _map_path {
    my ($self, $path) = @_;

    my $mapping = $self->{mapping};

    # No mapping - return path as-is (for X-Sendfile/Lighttpd)
    return $path unless defined $mapping;

    # Simple string prefix
    if (!ref $mapping) {
        return $mapping . $path;
    }

    # Hash mapping - find matching prefix and replace
    if (ref $mapping eq 'HASH') {
        for my $from (keys %$mapping) {
            if (substr($path, 0, length($from)) eq $from) {
                my $to = $mapping->{$from};
                return $to . substr($path, length($from));
            }
        }
    }

    # No mapping matched - return as-is
    return $path;
}

1;

__END__

=head1 EXAMPLE

Complete example with Nginx:

    # app.pl
    use PAGI::Middleware::Builder;
    use Future::AsyncAwait;

    my $app = builder {
        enable 'XSendfile',
            type    => 'X-Accel-Redirect',
            mapping => { '/var/www/protected/' => '/internal/' };

        async sub {
            my ($scope, $receive, $send) = @_;

            # Authenticate, authorize, etc.
            my $user = authenticate($scope);
            my $file = authorize_download($user, $scope->{path});

            await $send->({
                type    => 'http.response.start',
                status  => 200,
                headers => [
                    ['Content-Type', 'application/octet-stream'],
                    ['Content-Disposition', 'attachment; filename="file.bin"'],
                ],
            });
            await $send->({
                type => 'http.response.body',
                file => "/var/www/protected/$file",
            });
        };
    };

    # nginx.conf
    location /internal/ {
        internal;
        alias /var/www/protected/;
    }

=head1 WHY USE THIS?

Direct file serving from your application (even with sendfile) ties up a
worker process for the duration of the transfer. With X-Sendfile:

=over 4

=item * Your app worker is freed immediately after sending headers

=item * Nginx/Apache handle the file transfer using optimized kernel sendfile

=item * The proxy handles Range requests, caching, and connection management

=item * Works correctly with slow clients without blocking your app

=back

This is especially important for large files or slow client connections.

=head1 SEE ALSO

L<PAGI::Middleware> - Base class for middleware

L<Plack::Middleware::XSendfile> - Similar middleware for PSGI

L<https://www.nginx.com/resources/wiki/start/topics/examples/xsendfile/> - Nginx X-Accel-Redirect docs

L<https://tn123.org/mod_xsendfile/> - Apache mod_xsendfile

=cut
