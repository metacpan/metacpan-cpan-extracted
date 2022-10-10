package
    Pinto::Remote::SelfContained::Request;

use v5.10;
use Moo;

use Carp qw(croak);
use List::Util qw(pairgrep);
use MIME::Base64 qw(encode_base64);
use Path::Tiny qw(path);
use Pinto::Remote::SelfContained::Types qw(BodyPart Uri Username);
use Types::Standard qw(ArrayRef Enum HashRef Maybe Str);

use namespace::clean;

our $VERSION = '1.000';

has username => (is => 'ro', isa => Username, required => 1);
has password => (is => 'ro', isa => Maybe[Str], required => 1);

has method => (is => 'ro', isa => Enum[qw(GET POST PUT DELETE)], required => 1);
has uri => (is => 'ro', isa => Uri, coerce => 1, required => 1);

has accept => (is => 'ro', isa => Maybe[Str], default => 'application/vnd.pinto.v1+text');
has content_type => (is => 'ro', isa => Maybe[Str], default => 'multipart/form-data');
has headers => (is => 'ro', isa => HashRef[Str], default => sub { +{} });

has body_parts => (is => 'ro', isa => ArrayRef[BodyPart], default => sub { [] });

sub as_request_items {
    my ($self, $data_callback) = @_;

    return $self->method, $self->uri, $self->headers_and_body_as_options($data_callback);
}

sub headers_and_body_as_options {
    my ($self, $data_callback) = @_;
    my ($boundary, $body) = $self->boundary_and_body;
    return {
        pairgrep { defined $b }
        headers => $self->headers_hash($boundary),
        content => $body,
        data_callback => $data_callback,
    };
}

sub headers_hash {
    my ($self, $boundary) = @_;
    my $content_type = $self->content_type;
    $content_type .= "; boundary=$boundary" if defined $boundary;
    return {
        pairgrep { defined $b }
        %{ $self->headers },
        'Accept' => $self->accept,
        'Content-type' => $content_type,
        'Authorization' => $self->authorization_header,
    };
}

sub authorization_header {
    my ($self) = @_;
    my $password = $self->password // return undef;
    my $authorization = join ':', $self->username, $password;
    my $enc = encode_base64($authorization, '');
    return "Basic $enc";
}

sub boundary_and_body {
    my ($self) = @_;

    my @parts = map $self->body_part_as_content($_), @{ $self->body_parts }
        or return;

    my $boundary = 'aAAa';
    $boundary++ while grep /\n--\Q$boundary\E(?:--)?\r?\n/, @parts;

    my $body = join '', (
        (map +("--$boundary\r\n", $_), @parts),
        "--$boundary--\r\n",
    );

    return $boundary, $body;
}

sub body_part_as_content {
    my ($self, $body_part) = @_;

    (my $name_encoded = $body_part->{name}) =~ s/(["\\])/\\$1/g;
    my @ret = qq[Content-disposition: form-data; name="$name_encoded"];
    if (defined(my $filename = $body_part->{filename})) {
        (my $filename_encoded = path($filename)->basename) =~ s/(["\\])/\\$1/g;
        $ret[0] .= qq[; filename="$filename_encoded"];
    }

    push @ret, "Content-encoding: $_" for grep defined, $body_part->{encoding};
    push @ret, "Content-type: $_"     for grep defined, $body_part->{type};
    push @ret, '';
    push @ret, $body_part->{data} // path($body_part->{filename})->slurp_raw;
    $_ .= "\r\n" for @ret;
    return join '', @ret;
}

sub dump {
    my ($self, %opt) = @_;

    my $enc = sub {
        for (my $s = shift) {
            s/([\x00-\x08\x0B\x0C\x0E-\x1F\x7F-\xFF])/sprintf '\\%02x', ord $1/ge;
            s/\r/\\r/g;
            s/\t/\\t/g;
            return $_;
        }
    };

    my ($boundary, $body) = $self->boundary_and_body;
    my $headers = $self->headers_hash($boundary);

    my $ret = '';
    $ret .= sprintf "%s %s HTTP/1.0\\r\n", $self->method, $self->uri->path_query;

    for my $h (sort keys %$headers) {
        my $v = $enc->($headers->{$h});
        $ret .= sprintf "%s: %s\\r\n", $h, $v;
    }

    $ret .= "\\r\n";

    if (defined $body) {
        $opt{maxlength} //= 512;
        substr($body, $opt{maxlength}, length $ret, '')
            if $opt{maxlength} && length($body) > $opt{maxlength};

        $ret .= $enc->($body);
        $ret .= "\n";
    }

    print $ret if !defined wantarray;
    return $ret;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pinto::Remote::SelfContained::Request

=head1 NAME

Pinto::Remote::SelfContained::Request

=head1 NAME

Pinto::Remote::SelfContained::Request - request class for HTTP::Tiny

=head1 AUTHOR

Aaron Crane E<lt>arc@cpan.orgE<gt>, Brad Lhotsky E<lt>brad@divisionbyzero.netE<gt>

=head1 COPYRIGHT

Copyright 2020 Aaron Crane.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself. See L<http://dev.perl.org/licenses/>.

=cut
