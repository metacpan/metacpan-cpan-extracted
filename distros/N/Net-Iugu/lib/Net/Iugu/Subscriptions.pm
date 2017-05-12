package Net::Iugu::Subscriptions;
$Net::Iugu::Subscriptions::VERSION = '0.000002';
use Moo;
extends 'Net::Iugu::CRUD';

sub suspend {
    my ( $self, $sub_id ) = @_;

    my $uri = $self->endpoint . '/' . $sub_id . '/suspend';

    return $self->request( POST => $uri );
}

sub activate {
    my ( $self, $sub_id ) = @_;

    my $uri = $self->endpoint . '/' . $sub_id . '/activate';

    return $self->request( POST => $uri );
}

sub change_plan {
    my ( $self, $sub_id, $plan_id ) = @_;

    my $uri = $self->endpoint . '/' . $sub_id . '/change_plan/' . $plan_id;

    return $self->request( POST => $uri );
}

sub add_credits {
    my ( $self, $sub_id, $quantity ) = @_;

    my $uri = $self->endpoint . '/' . $sub_id . '/add_credits';

    return $self->request( PUT => $uri, { quantity => $quantity } );
}

sub remove_credits {
    my ( $self, $sub_id, $quantity ) = @_;

    my $uri = $self->endpoint . '/' . $sub_id . '/remove_credits';

    return $self->request( PUT => $uri, { quantity => $quantity } );
}

1;

# ABSTRACT: Net::Iugu::Subscriptions - Methods to manage subscriptions

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Iugu::Subscriptions - Net::Iugu::Subscriptions - Methods to manage subscriptions

=head1 VERSION

version 0.000002

=head1 SYNOPSIS

Implements the API calls to manage subscriptions of Iugu accounts. It is used
by the main module L<Net::Iugu> and shouldn't be instantiated directly.

    use Net::Iugu::Subscriptions;

    my $subs = Net::Iugu::Subscriptions->new(
        token => 'my_api_token'
    );

    my $res;

    $res = $subs->create( $data );
    $res = $subs->read( $subscription_id );
    $res = $subs->update( $subscription_id, $data );
    $res = $subs->delete( $subscription_id );
    $res = $subs->list( $params );
    $res = $subs->suspend( $subscription_id );
    $res = $subs->activate( $subscription_id );
    $res = $subs->change_plan( $subscription_id, $plan_id );
    $res = $subs->add_credits( $subscription_id, $amount );
    $res = $subs->remove_credits( $subscription_id, $amount );

For a detailed reference of params and return values check the
L<Official Documentation|http://iugu.com/referencias/api#assinaturas>.

=head1 METHODS

=head2 create( $data )

Inherited from L<Net::Iugu::CRUD>, creates a new subscription.

=head2 read( $subscription_id )

Inherited from L<Net::Iugu::CRUD>, returns data of a subscription.

=head2 update( $subscription_id, $data )

Inherited from L<Net::Iugu::CRUD>, updates a subscription.

=head2 delete( $subscription_id )

Inherited from L<Net::Iugu::CRUD>, removes a subscription.

=head2 list( $params )

Inherited from L<Net::Iugu::CRUD>, lists all subscriptions.

=head2 suspend( $subscription_id )

Suspends a subscription.

=head2 activate( $subscription_id )

Activates a subscription.

=head2 change_plan( $subscription_id, $plan_id )

Changes the plan of a subscrption.

=head2 add_credits( $subscription_id, $amount )

Adds creditis to a subscription.

=head2 remove_credits( $subscription_id, $amount )

Removes credits from a subscription.

=head1 AUTHOR

Blabos de Blebe <blabos@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Blabos de Blebe.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
