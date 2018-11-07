package QBit::WebInterface::OwnServer;
$QBit::WebInterface::OwnServer::VERSION = '0.008';
use qbit;

use base qw(QBit::WebInterface);

use IO::Socket;
use MIME::Types;

use QBit::WebInterface::OwnServer::Request;
use QBit::WebInterface::Response;

sub run {
    my ($self, %opts) = @_;

    $opts{'port'} ||= 5000;

    my $server_socket = IO::Socket::INET->new(
        Proto     => 'tcp',
        LocalPort => $opts{'port'},
        Listen    => SOMAXCONN,
        Reuse     => 1,
      )
      || throw Exception gettext('Cannot create socket');

    l "http://127.0.0.1:$opts{'port'}";
    l "Ctrl+C to terminate";

    my $mimetypes = MIME::Types->new();

    while (my $socket = $server_socket->accept()) {
        try {
            $self->request(QBit::WebInterface::OwnServer::Request->new(socket => $socket, port => $opts{'port'}));

            l $self->request->uri;

            if (length(my $static_path = $self->_is_static($self->request->uri))) {
                if ($static_path =~ /\.\.\// || !-f $static_path) {
                    $self->response(QBit::WebInterface::Response->new(status => 404));
                } else {
                    my $mimetype = $mimetypes->mimeTypeOf($static_path);

                    $self->response(
                        QBit::WebInterface::Response->new(
                            status => 200,
                            data   => \readfile($static_path, binary => $mimetype && $mimetype->isBinary()),
                        )
                    );
                    $self->response->content_type($mimetype->type() . ($mimetype->isAscii() ? '; charset=UTF-8' : ''))
                      if $mimetype;
                }
            } else {
                $self->build_response();
            }
        }
        catch {
            l shift->as_string();
            $self->response(QBit::WebInterface::Response->new()) unless $self->response();
            $self->response->status(500);
            $self->response->data('');
        };

        binmode($socket);

        my $status = $self->response->status || 200;

        print $socket "HTTP/1.0 $status "
          . (
            exists($QBit::WebInterface::HTTP_STATUSES{$status})
            ? " $QBit::WebInterface::HTTP_STATUSES{$status}"
            : 'Unknown'
          )
          . "\n";
        print $socket 'Server: QBit::WebInterface::OwnServer (' . ref($self) . ")\n";
        print $socket 'Set-Cookie: ' . $_->as_string() . "\n" foreach values(%{$self->response->cookies});

        while (my ($key, $value) = each(%{$self->response->headers})) {
            print $socket "$key: $value\n";
        }

        if ($status == 200) {
            print $socket 'Content-Type: ' . $self->response->content_type . "\n\n";

            my $filename = $self->response->filename;
            if (defined($filename)) {
                utf8::encode($filename) if utf8::is_utf8($filename);

                print $socket 'Content-Disposition: '
                  . 'attachment; filename="'
                  . $self->_escape_filename($self->response->filename) . '"';
            }

            if (defined($self->response->data)) {
                my $data_ref = ref($self->response->data) ? $self->response->data : \$self->response->data;
                utf8::encode($$data_ref) if utf8::is_utf8($$data_ref);
                print $socket $$data_ref;
            }

        } elsif ($status == 301 || $status == 302) {
            print $socket 'Location: ' . $self->response->location . "\n\n";
        } elsif ($status == 404) {
            print $socket "Content-Type: text/html\n\n";
            print $socket '<html><body><h1>Not found</h1><body></html>';
        } elsif ($status == 500) {
            print $socket "Content-Type: text/html\n\n";
            print $socket '<html><body><h1>Internal server error</h1><body></html>';
        } else {
            print $socket "\n\n";
        }

        close($socket);
    }
}

sub _is_static {
    my ($self, $uri) = @_;

    my $path = __normalize_path($uri);

    $self->{'static_locations'} ||= {'/qbit' => $self->{'__ORIG_OPTIONS__'}{'FrameworkPath'} . 'QBit/data'};

    foreach my $l (sort {length($b) <=> length($a)} keys(%{$self->{'static_locations'}})) {
        my $location = $l;
        $location =~ s/\/$//;
        if ($path =~ /^$location\/(.+)$/) {
            return "$self->{'static_locations'}{$l}/$1";
        }
    }

    return '';

}

sub __normalize_path {
    my ($path) = @_;

    for ($path) {
        s/\?.+$//;
        s/[^\/a-zA-Z0-9_\.-]//g;
        while (s/\/[a-zA-Z0-9_-]+?\/\.\.(\/|$)/$1/) { }
    }

    return $path;
}

TRUE;

__END__

=encoding utf8

=head1 Name

QBit::WebInterface::OwnServer - WebInterface with own HTTP server.

=head1 GitHub

https://github.com/Madskill/QBit-WebInterface-OwnServer

=head1 Install

=over

=item *

cpanm QBit::WebInterface::OwnServer

=back

For more information. please, see code.

=cut
