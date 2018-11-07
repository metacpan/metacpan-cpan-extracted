package QBit::WebInterface::PSGI;
$QBit::WebInterface::PSGI::VERSION = '0.005';
use qbit;

use base qw(QBit::WebInterface);

use QBit::WebInterface::PSGI::Request;

sub run {
    my ($self) = @_;

    $self = $self->new() unless blessed($self);

    return sub {
        my ($env) = @_;

        $self->request(QBit::WebInterface::PSGI::Request->new(ENV => $env));

        $self->build_response();

        my $data_ref = \$self->response->data;
        if (defined($data_ref)) {
            $data_ref = $$data_ref if ref($$data_ref);
            utf8::encode($$data_ref) if defined($$data_ref) && utf8::is_utf8($$data_ref);
        }
        $data_ref = \'' unless defined($$data_ref);

        my $status = $self->response->status || 200;

        my @headers = ();
        my @data    = ();

        push(
            @headers,
            'Status' => $status
              . (
                exists($QBit::WebInterface::HTTP_STATUSES{$status})
                ? " $QBit::WebInterface::HTTP_STATUSES{$status}"
                : ''
              )
        );

        push(@headers, 'Set-Cookie' => $_->as_string()) foreach values(%{$self->response->cookies});

        while (my ($key, $value) = each(%{$self->response->headers})) {
            push(@headers, $key => $value);
        }

        if (!$self->response->status || $self->response->status == 200) {
            push(@headers, 'Content-Type' => $self->response->content_type);

            my $filename = $self->response->filename;
            if (defined($filename)) {
                utf8::encode($filename) if utf8::is_utf8($filename);

                push(@headers,
                    'Content-Disposition' => 'attachment; filename="' . $self->_escape_filename($filename) . '"');
            }

            push(@data, $$data_ref);
        } elsif ($self->response->status == 301 || $self->response->status == 302) {
            push(@headers, 'Location' => $self->response->location);
        }

        return [$status, \@headers, \@data];
    };
}

TRUE;

__END__

=encoding utf8

=head1 Name

QBit::WebInterface::PSGI - Package for connect WebInterface with PSGI.

=head1 GitHub

https://github.com/QBitFramework/QBit-WebInterface-PSGI

=head1 Install

=over

=item *

cpanm QBit::WebInterface::PSGI

=back

For more information. please, see code.

=cut
