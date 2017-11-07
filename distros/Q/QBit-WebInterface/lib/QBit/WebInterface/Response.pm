package QBit::WebInterface::Response;
$QBit::WebInterface::Response::VERSION = '0.030';
use qbit;

use base qw(QBit::Class);

use CGI::Cookie;

__PACKAGE__->mk_accessors(
    qw(
      content_type
      cookies
      data
      filename
      location
      status
      headers
      timelog
      )
);

sub init {
    my ($self) = @_;

    $self->content_type('text/html; charset=UTF-8');
    $self->cookies({});
    $self->headers({});
}

sub add_cookie {
    my ($self, $name, $value, %opts) = @_;

    $self->cookies->{$name} = CGI::Cookie->new(
        -name  => $name,
        -value => $value,
        (map {'-' . $_ => $opts{$_}} grep {exists($opts{$_})} qw(expires domain path secure)),
    );
}

sub delete_cookie {
    my ($self, $name) = @_;

    $self->cookies->{$name} = CGI::Cookie->new(
        -name   => $name,
        -value  => '',
        expires => '-10Y',
    );
}

TRUE;
