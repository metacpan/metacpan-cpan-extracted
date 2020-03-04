package Pcore::API::Proxy::http;

use Pcore -class;

with qw[Pcore::API::Proxy];

has is_http => 1;

around new => sub ( $orig, $self, $uri ) {
    $self = $self->$orig;

    $self->{uri} = $uri;

    return $self;
};

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::API::Proxy::http

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
