package Pcore::API::Proxy::socks;

use Pcore -class;

with qw[Pcore::API::Proxy];

has is_socks  => 1;
has is_socks5 => 1;

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

Pcore::API::Proxy::socks

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
