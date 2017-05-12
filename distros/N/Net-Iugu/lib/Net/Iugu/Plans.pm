package Net::Iugu::Plans;
$Net::Iugu::Plans::VERSION = '0.000002';
use Moo;
extends 'Net::Iugu::CRUD';

sub read_by_identifier {
    my ( $self, $identifier ) = @_;

    my $uri = $self->endpoint . '/identifier/' . $identifier;

    return $self->request( GET => $uri );
}

1;

# ABSTRACT: Net::Iugu::Plans - Methods to manage plans

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Iugu::Plans - Net::Iugu::Plans - Methods to manage plans

=head1 VERSION

version 0.000002

=head1 SYNOPSIS

Implements the API calls to manage plans of Iugu accounts. It is used
by the main module L<Net::Iugu> and shouldn'tb e instantiated directly.

    use Net::Iugu::Plans;

    my $plans = Net::Iugu::Plans->new(
        token => 'my_api_token'
    );

    my $res;

    $res = $plans->create( $data );
    $res = $plans->read( $plan_id );
    $res = $plans->read_by_identifier( $plan_id );
    $res = $plans->update( $plan_id, $data );
    $res = $plans->delete( $plan_id );
    $res = $plans->list( $params );

For a detailed reference of params and return values check the
L<Official Documentation|http://iugu.com/referencias/api#planos>.

=head1 METHODS

=head2 create( $data )

Inherited from L<Net::Iugu::CRUD>, creates a new plan.

=head2 read( $plan_id )

Inherited from L<Net::Iugu::CRUD>, returns data of a plan.

=head2 read_by_identifier( $identifier_id )

Returns data of a plan using an identifier ID.

=head2 update( $plan_id, $data )

Inherited from L<Net::Iugu::CRUD>, updates a plan.

=head2 delete( $plan_id )

Inherited from L<Net::Iugu::CRUD>, removes a plan.

=head2 list( $params )

Inherited from L<Net::Iugu::CRUD>, lists all plans.

=head1 AUTHOR

Blabos de Blebe <blabos@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Blabos de Blebe.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
