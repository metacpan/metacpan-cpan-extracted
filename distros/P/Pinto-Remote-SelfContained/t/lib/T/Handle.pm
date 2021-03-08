package
    T::Handle; # hide from PAUSE

use v5.10;
use Moo;

use namespace::clean;

has buffer => (is => 'ro', required => 1);
has request => (is => 'ro', required => 1);
has timeout => (is => 'rw'); # ignored

has response_header => (
    is => 'bare',
    lazy => 1,
    reader => 'read_response_header',
    builder => '_build_response_header',
);

has response_body => (is => 'lazy', builder => sub {
    my ($self) = @_;
    my $buffer = $self->buffer;
    $buffer =~ s/\A .*? \x0D?\x0A \x0D?\x0A//xs
        or die "No break between header and body\n";
    return $buffer;
});

sub _assert_ssl {}
sub _find_CA_file {}
sub can_reuse { 0 }
sub close { 1 }
sub connect { $_[0] }
sub start_ssl {}

sub write_request {
    my ($self, $request) = @_;
    return if !$request->{cb};
    $self->request->{body} //= '';
    while () {
        my $chunk = $request->{cb}->();
        last if !defined $chunk || !length $chunk;
        $self->request->{body} .= $chunk;
    }
}

sub _build_response_header {
    my ($self) = @_;

    my $buffer = $self->buffer;
    $buffer =~ s{\A (HTTP/0*[0-9]+\.0*[0-9]+) [\x09\x20]+ ([0-9]{3}) [\x09\x20]+ ([^\x0D\x0A]*) \x0D?\x0A}{}x
        or die "Please pass a valid response header\n";

    my ($protocol, $status, $reason) = ($1, $2, $3);

    my %headers;
    # XXX: This doesn't handle continuation lines
    while ($buffer =~ s{^ ([^\x0D\x0A]*) \x0D?\x0A }{}x) {
        my $line = $1;
        last if $line eq '';
        my ($field_name, $field_value) = split /: [\x09\x20]* /x, $line
            or die "Malformed header line $line\n";
        if (!exists $headers{$field_name}) {
            $headers{$field_name} = $field_value;
        }
        else {
            for ($headers{$field_name}) {
                $_ = [$_] if !ref;
                push @$_, $field_value;
            }
        }
    }

    return {
        status       => $status,
        reason       => $reason,
        headers      => \%headers,
        protocol     => $protocol,
    };
}

sub read_body {
    my ($self, $callback, $partial_response) = @_;

    $callback->($_, $partial_response)
        # Use 8-byte chunks, so we exercise the caller's chunk handling
        for unpack '(a8)*', $self->response_body;

    return;
}

1;
