package PAGI::App::Redirect;
$PAGI::App::Redirect::VERSION = '0.002001';
use strict;
use warnings;
use Future::AsyncAwait;
use PAGI::Response;

=encoding UTF-8

=head1 NAME

PAGI::App::Redirect - URL redirect app for the dynamic case

=head1 SYNOPSIS

    # The static case is just a response value (preferred):
    use PAGI::Response;
    $router->mount('/old' => PAGI::Response->redirect('/new', 301));

    # PAGI::App::Redirect is for the dynamic case — a coderef target
    # and/or query-string preservation:
    use PAGI::App::Redirect;
    my $app = PAGI::App::Redirect->new(
        to             => sub { my ($scope) = @_; compute_target($scope) },
        status         => 302,
        preserve_query => 1,
    )->to_app;

=cut

sub new {
    my ($class, %args) = @_;

    return bless {
        to => $args{to},
        status => $args{status} // 302,
        preserve_query => $args{preserve_query} // 1,
    }, $class;
}

sub to_app {
    my ($self) = @_;

    my $to = $self->{to};
    my $status = $self->{status};
    my $preserve_query = $self->{preserve_query};

    return async sub {
        my ($scope, $receive, $send) = @_;
        my $location = ref $to eq 'CODE' ? $to->($scope) : $to;

        if ($preserve_query && $scope->{query_string}) {
            my $sep = $location =~ /\?/ ? '&' : '?';
            $location .= $sep . $scope->{query_string};
        }

        await PAGI::Response->new($scope)
            ->content_type('text/plain')
            ->redirect($location, $status)
            ->respond($send);
    };
}

1;

__END__

=head1 DESCRIPTION

Performs HTTP redirects where the target is computed per request or
query-string preservation is required. For a fixed target with no
query-string handling, prefer L<PAGI::Response/redirect> directly:

    PAGI::Response->redirect('/new', 301);

Use this module when the redirect target is a coderef that receives
C<$scope> and returns the URL at request time, or when you need the
C<preserve_query> option to automatically append the incoming query
string to the redirect target.

=head1 OPTIONS

=over 4

=item * C<to> - Target URL (string or coderef receiving $scope)

=item * C<status> - HTTP status code (default: 302)

=item * C<preserve_query> - Append query string to target (default: 1)

=back

=cut
