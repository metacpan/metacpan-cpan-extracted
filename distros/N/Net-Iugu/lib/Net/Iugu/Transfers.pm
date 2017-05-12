package Net::Iugu::Transfers;
$Net::Iugu::Transfers::VERSION = '0.000002';
use Moo;
extends 'Net::Iugu::Request';

sub transfer {
    my ( $self, $data ) = @_;

    my $uri = $self->endpoint;

    return $self->request( POST => $uri, $data );
}

sub list {
    my ($self) = @_;

    my $uri = $self->endpoint;

    return $self->request( GET => $uri );
}

1;

# ABSTRACT: Net::Iugu::Transfers - Methods to transfer money between accounts

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Iugu::Transfers - Net::Iugu::Transfers - Methods to transfer money between accounts

=head1 VERSION

version 0.000002

=head1 SYNOPSIS

Implements the API calls to make transfers between Iugu accounts. It is used
by the main module L<Net::Iugu> and shouldn't be instantiated direclty.

    use Net::Iugu::Transfers;

    $transfers = Net::Iugu::Transfers->new(
        token => 'my_api_token'
    );

    my $res  = $transfers->transfer( $data );
    my $list = $transfers->list;

For a detailed reference of params and return values check the
L<Official Documentation|http://iugu.com/referencias/api#transferências-de-valores>.

=head1 METHODS

=head2 transfer( $data )

Transfer an amount of money from your account to another account.

=head2 list()

Return a list of all transfers previously made.

=head1 AUTHOR

Blabos de Blebe <blabos@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Blabos de Blebe.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
