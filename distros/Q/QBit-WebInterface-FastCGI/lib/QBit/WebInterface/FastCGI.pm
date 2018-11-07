package QBit::WebInterface::FastCGI;
$QBit::WebInterface::FastCGI::VERSION = '0.006';
use qbit;

use base qw(QBit::WebInterface);

use QBit::WebInterface::FastCGI::Request;

sub run {
    my ($self, $r) = @_;

    $self = $self->new() unless blessed($self);

    $self->request(QBit::WebInterface::FastCGI::Request->new(request => $r));

    $self->build_response();

    my $data_ref = \$self->response->data;
    if (defined($data_ref)) {
        $data_ref = $$data_ref if ref($$data_ref);
        utf8::encode($$data_ref) if defined($$data_ref) && utf8::is_utf8($$data_ref);
    }
    $data_ref = \'' unless defined($$data_ref);

    binmode(STDOUT);

    my $status = $self->response->status || 200;
    print "Status: $status"
      . (exists($QBit::WebInterface::HTTP_STATUSES{$status}) ? " $QBit::WebInterface::HTTP_STATUSES{$status}" : '')
      . "\n";
    print 'Set-Cookie: ' . $_->as_string() . "\n" foreach values(%{$self->response->cookies});

    while (my ($key, $value) = each(%{$self->response->headers})) {
        print "$key: $value\n";
    }

    if (!$self->response->status || $self->response->status == 200) {
        print 'Content-Type: ' . $self->response->content_type . "\n";

        my $filename = $self->response->filename;
        if (defined($filename)) {
            utf8::encode($filename) if utf8::is_utf8($filename);

            print 'Content-Disposition: attachment; filename="' . $self->_escape_filename($filename) . "\"\n";
        }

        print "\n", $$data_ref;
    } elsif ($self->response->status == 301 || $self->response->status == 302) {
        print 'Location: ' . $self->response->location . "\n\n";
    } else {
        print "\n";
    }
}

TRUE;

__END__

=encoding utf8

=head1 Name
 
QBit::WebInterface::FastCGI - Package for connect WebInterface with FastCGI.

=head1 GitHub

https://github.com/QBitFramework/QBit-WebInterface-FastCGI

=head1 Install

=over

=item *

cpanm QBit::WebInterface::FastCGI

=item *

apt-get install libqbit-webinterface-fastcgi-perl (http://perlhub.ru/)

=back

For more information. please, see code.

=cut
