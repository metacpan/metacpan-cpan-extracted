package Test::Apache2::RequestRec;
use strict;
use warnings;
use base qw(Test::Apache2::RequestUtil);

use URI;
use APR::Pool;
use APR::Table;
use Scalar::Util;
use HTTP::Response;

__PACKAGE__->mk_accessors(
    qw(status)
);
__PACKAGE__->mk_ro_accessors(
    qw(headers_in headers_out err_headers_out
       method content response_body pool)
);

sub new {
    my ($class, @args) = @_;

    if (Scalar::Util::blessed($args[0])) {
        $class->_new_from_request(@args);
    } else {
        $class->_new_from_hash_ref(@args);
    }
}

sub _new_from_hash_ref {
    my ($class, @args) = @_;

    my $self = $class->SUPER::new(@args);

    if (@args) {
        $self->{_real_uri} = URI->new($args[0]->{uri});
    } else {
        $self->{_real_uri} = URI->new('http://example.com/');
    }

    my $pool = APR::Pool->new;
    map {
        $self->{ $_ } = APR::Table::make($pool, 0);
    } qw(headers_out err_headers_out subprocess_env);

    my $headers_in = APR::Table::make($pool, 0);
    while (my ($key, $value) = each %{ $self->{headers_in} }) {
        $headers_in->set($key => $value);
    }
    $self->{headers_in} = $headers_in;
    $self->{pool} = $pool;

    if (! defined $self->location) {
        $self->location($self->uri);
    }

    return $self;
}

sub _new_from_request {
    my ($class, $req) = @_;

    my %headers_in = map {
        $_ => $req->header($_);
    } $req->header_field_names;

    return $class->new({
        method => $req->method,
        uri => $req->uri,
        headers_in => \%headers_in,
        content => $req->content,
    });
}

sub uri {
    my ($self) = @_;
    $self->{_real_uri}->path;
}

sub unparsed_uri {
    my ($self) = @_;
    $self->{_real_uri}->path_query;
}

sub get_server_port {
    my ($self) = @_;
    $self->{_real_uri}->port;
}

sub hostname {
    my ($self) = @_;
    $self->{_real_uri}->host;
}

sub path_info {
    my $self = shift;
    my $path_info = $self->uri->path;
    $self->uri->path(shift()) if @_;
    return $path_info;
}

sub path {
    my ($self) = @_;
    $self->{_real_uri}->path_query;
}

sub header_in {
    my ($self, $key) = @_;
    return $self->headers_in->get($key);
}

sub header_out {
    my ($self, $key, $value) = @_;
    return $self->headers_out->set($key, $value);
}

sub content_type {
    my $self = shift;

    $self->headers_out->set('Content-Type', shift) if @_;
    return $self->headers_out->get('Content-Type');
}

sub send_http_header {
}

sub subprocess_env {
    my ($self, $key, $value) = @_;

    if ($value) {
        $self->subprocess_env->set($key, $value);
    } elsif ($key) {
        $self->subprocess_env->get($key);
    } else {
        $self->{subprocess_env};
    }
}

sub args {
    my ($self, $value) = @_;
    if (defined $value) {
      $self->{_real_uri}->query($value);
    }
    return $self->{_real_uri}->query;
}

sub set_content_length {
    ;
}

sub to_response {
    my ($self) = @_;
    my $result = HTTP::Response->new;

    $self->headers_out->do(sub {
        $result->header($_[0], $_[1]);
        return 1;
    });
    $result->code($self->status);

    # TODO: don't access superclass's variable directly
    $self->{response_body_io}->close;

    $result->content($self->response_body);

    return $result;
}

1;


=head1 NAME

Test::Apache2::RequestRec - Fake Apache2::RequestRec

=head1 DESCRIPTION

Apache2::RequestRec don't allow you to create an instance manually,
because the instance created automatically by mod_perl.

So this class provides same interface as Apache2::RequestRec
except a public constructor and some setters.

=head1 SEE ALSO

L<Apache2::RequestRec>

=cut
