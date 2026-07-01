package PAGI::App::NotFound;
$PAGI::App::NotFound::VERSION = '0.002001';
use strict;
use warnings;
use Future::AsyncAwait;
use PAGI::Response;

=head1 NAME

PAGI::App::NotFound - Customizable 404 response

=head1 SYNOPSIS

    # A fixed 404 is just a response value (preferred):
    use PAGI::Response;
    $router->mount('/missing' => PAGI::Response->text('Not Found')->status(404));

    # PAGI::App::NotFound is for a computed body or custom defaults
    # (e.g. a Cascade fallback):
    use PAGI::App::NotFound;
    my $app = PAGI::App::NotFound->new(
        status       => 404,
        content_type => 'text/html',
        body         => sub { my ($scope) = @_; render_404($scope) },
    )->to_app;

=cut

sub new {
    my ($class, %args) = @_;

    return bless {
        body => $args{body} // 'Not Found',
        content_type => $args{content_type} // 'text/plain',
        status => $args{status} // 404,
    }, $class;
}

sub to_app {
    my ($self) = @_;

    my $body         = $self->{body};
    my $content_type = $self->{content_type};
    my $status       = $self->{status};

    return async sub {
        my ($scope, $receive, $send) = @_;
        my $b = ref $body eq 'CODE' ? $body->($scope) : $body;

        await PAGI::Response->new($scope)
            ->status($status)
            ->content_type($content_type)
            ->send_raw($b)
            ->respond($send);
    };
}

1;

__END__

=head1 DESCRIPTION

For a fixed body, prefer a L<PAGI::Response> value directly (e.g.
C<< PAGI::Response->text('Not Found', status => 404) >>). Use this module
when you need a per-request (coderef) body or non-default content type or
status code as a Cascade fallback.

Returns a customizable 404 (or other status) response. Useful as a
fallback in a Cascade.

=head1 OPTIONS

=over 4

=item * C<body> - Response body (string or coderef, default: 'Not Found')

=item * C<content_type> - Content-Type header (default: 'text/plain')

=item * C<status> - HTTP status code (default: 404)

=back

=cut
