package Mojo::UserAgent::UnixSocket;
use Carp 'carp';
use Mojo::Base 'Mojo::UserAgent';
use DummySocket;

our $VERSION = '0.021';

sub start {
    my ($self, $tx, $cb) = @_;
    if ($tx->req->url->scheme eq 'unix') {
        my $path = $tx->req->url->path;

        # pull out the sock_path ('host') and url path.
        my $sock_path = ($path =~ m#(^.+\.sock)\/#)[0];
        (my $url_path = $path) =~ s/$sock_path//;
        $tx->req->url->path($url_path);
        $tx->req->url->host('localhost');

        if (-S $sock_path) {
            my $sock = DummySocket->new(Peer => $sock_path);
            $tx->connection($sock);
        } else {
            my $message = "$sock_path is not a readable socket.";
            carp $message;
            $tx->req->error({message => $message});
        }
    }
    $self->SUPER::start($tx, $cb);
}

1;

=encoding utf8

=head1 NAME

Mojo::UserAgent::UnixSocket - User Agent connections over UNIX sockets.

=head1 VERSION

0.01

=head1 SYNOPSIS

  use Mojo::UserAgent::UnixSocket;

  my $ua = Mojo::UserAgent::UnixSocket->new;
  say $ua->get('unix:///var/run/docker.sock/images/json?all=true')->res->body;

=head1 DESCRIPTION

L<Mojo::UserAgent::UnixSocket> transparently enables L<Mojo::UserAgent> to interact with services listening on Unix domain sockets.

Any invocation that works with L<Mojo::UserAgent> should also work here.

It expects URLs in the following format (the .sock is required, pending a clever patch):

  unix://<path-to-socket>.sock/<url-path>

For example, talking to the L<Docker|http:www.//docker.io/> daemon, whose socket is (typically) located at C</var/run/docker.sock>:

  unix:///var/run/docker.sock/images/nginx/json

=head1 SEE ALSO

L<HTTP::Tiny::UNIX>, L<Mojo::UserAgent>

=cut

