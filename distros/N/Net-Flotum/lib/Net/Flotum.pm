package Net::Flotum;
use strict;
use 5.008_005;
our $VERSION = '0.10';

use warnings;
use utf8;
use Carp qw/croak confess/;
use Moo;
use namespace::clean;

use Net::Flotum::API::Charge;
use Net::Flotum::API::Customer;
use Net::Flotum::API::RequestHandler;
use Log::Any;
use Net::Flotum::Object::Customer;

has 'logger'    => ( is => 'ro', builder => '_build_logger',    lazy => 1 );
has 'requester' => ( is => 'ro', builder => '_build_requester', lazy => 1 );
has 'merchant_api_key' => ( is => 'rw', required => 1 );

has 'customer_api' => ( is => 'ro', builder => '_build_customer_api', lazy => 1 );
has 'charge_api'   => ( is => 'ro', builder => '_build_charge_api',   lazy => 1 );

sub _build_requester {
    Net::Flotum::API::RequestHandler->new;
}

sub _build_logger {
    Log::Any->get_logger;
}

sub _build_customer_api {
    my ($self) = @_;
    Net::Flotum::API::Customer->new( flotum => $self, );
}

sub _build_charge_api {
    my ($self) = @_;

    Net::Flotum::API::Charge->new( flotum => $self );
}

sub load_customer {
    my ( $self, %opts ) = @_;

    my $lazy = 1 if exists $opts{lazy} && $opts{lazy};
    my $cus;
    if ( exists $opts{id} ) {
        $cus = Net::Flotum::Object::Customer->new(
            flotum => $self,
            id     => $opts{id}
        );
        $cus->_load_from_id unless $lazy;
    }
    elsif ( exists $opts{remote_id} ) {
        $cus = Net::Flotum::Object::Customer->new(
            flotum => $self,
            id     => '_ID_IS_REQUIRED_'
        );
        $cus->_load_from_remote_id( $opts{remote_id} );
    }
    else {
        croak 'missing parameter: `remote_id` or `id` is required';
    }

    return $cus;
}

sub new_customer {
    my ( $self, %opts ) = @_;

    my $customer_id = $self->customer_api->exec_new_customer(%opts);

    return Net::Flotum::Object::Customer->new(
        flotum => $self,
        %$customer_id
    );
}

sub _new_charge {
    my $self = shift;
    return $self->charge_api->exec_new_charge(@_);
}

sub _update_customer {
    my $self = shift;
    return $self->customer_api->exec_update_customer(@_);
}

sub _payment_charge {
    my $self = shift;

    return $self->charge_api->exec_payment_charge(@_);
}

sub _capture_charge {
    my $self = shift;

    return $self->charge_api->exec_capture_charge(@_);
}

sub _refund_charge {
    my $self = shift;

    return $self->charge_api->exec_refund_charge(@_);
}

sub _get_customer_data {
    my ( $self, %opts ) = @_;

    confess 'missing parameter: `remote_id` or `id` is required'
      unless ( exists $opts{remote_id} && defined $opts{remote_id} )
      || ( exists $opts{id} && defined $opts{id} );

    return $self->customer_api->exec_load_customer(%opts);

}

sub _get_customer_session_key {
    my ( $self, %opts ) = @_;

    confess 'missing parameter: `id` is required'
      unless ( exists $opts{id} && defined $opts{id} );

    return $self->customer_api->exec_get_customer_session(%opts)->{api_key};
}

sub _get_list_customer_credit_cards {
    my ( $self, %opts ) = @_;

    confess 'missing parameter: `id` is required'
      unless ( exists $opts{id} && defined $opts{id} );

    my $arr = $self->customer_api->exec_list_credit_cards(%opts)->{credit_cards};
    return wantarray ? @$arr : $arr;
}

sub _remove_customer_credit_cards {
    my ( $self, %opts ) = @_;

    confess 'missing parameter: `id` is required'
      unless ( exists $opts{id} && defined $opts{id} );
    confess 'missing parameter: `merchant_customer_id` is required'
      unless ( exists $opts{merchant_customer_id} && defined $opts{merchant_customer_id} );

    my $bool = $self->customer_api->exec_remove_credit_card(%opts);
    return $bool;
}

1;

__END__

=encoding utf-8

=head1 NAME

Net-Flotum - use Flotum as your payment gateway

=head1 SYNOPSIS

    use Net::Flotum;

    $flotum = Net::Flotum->new(
        merchant_api_key => 'foobar',
    );

    # returns a Net::Flotum::Object::Customer
    $customer = $flotum->new_customer(

        name  => 'name here',
        remote_id => 'your id here',
        legal_document => '...',
        default_address_neighbourhood => '...'
    );

    # try to load field 'foobar' from $customer
    $customer->foobar

    # set customer new name
    $customer->update( name => 'new name' )

    # returns a Net::Flotum::Object::Customer
    $customer = $flotum->load_customer(

        # via remote_id
        remote_id => 'foobar',
        # or via id
        id => '0b912879-7c7b-42a1-8f49-722f13b67ae6'

        # lazy load (only works with `id`, lazy loading with `remote_id` is not supported)
        lazy => 1

    );

    # returns a hash reference containing details for creating an credit card.
    $http_description = $customer->new_credit_card();
    # something like that
    {
        accept     :  "application/json",
        fields     :  {
            address_city         :  "?Str",
            address_inputed_at   :  "?GmtDateTime",
            address_name         :  "?Str",
            address_neighbourhood:  "?Str",
            address_number       :  "?Str",
            address_observation  :  "?Str",
            address_state        :  "?Str",
            address_street       :  "?Str",
            address_zip          :  "?Str",
            brand                :  "*Brand",
            csc                  :  "*CSC",
            legal_document       :  "*Str",
            name_on_card         :  "*Str",
            number               :  "*CreditCard",
            validity             :  "*YYYYDD"
        },
        href       :  "https://default.flotum.com/customers/9baa2e37-2cb0-4c5c-9fe0-b2d91fdd53fe/credit-cards/?api_key=xxxx",
        method     :  "POST",
        valid_until:  1448902516
    }
    # ? means not required
    # * means required.
    # Str = Any String, CreditCard = credit card number, YYYYMD = Year+Month (2 pad)
    # Brands acceptance may vary, but may be one or more of bellow:
    # visa|mastercard|discover|americanexpress|jcb|enroute|bankcard|solo|chinaunionpay|laser|isracard|aura|elo


    # returns a list of Net::Flotum::Object::CreditCard
    @credit_cards = $customer->list_credit_cards();

    # Creating a charge.
    my $charge = $customer->new_charge(
        amount   => 100,
        currency => 'bra',
        metadata => {
            'Please use' => 'The way you need',
            'but'        => 'Do not use more than 10000 bytes after encoded in JSON',
        }
    );

    # Doing payment.
    my $payment = $charge->payment(
        customer_credit_card_id => $customer_credit_card_id,
        csc_check               => '000',
    );

    # Capture.
    my $capture = $charge->capture(description => "is optional");
    print $capture->{transaction_status} . "\n"; # authorized

    # Refund.
    my $refund = $charge->refund();
    print $refund->{status} . "\n";             # aborted
    print $refund->{transaction_status} . "\n"; # in-cancellation


=head1 DESCRIPTION

this is WIP work, please check this page later! Flotum is currently only being used on eokoe.com startups.

Flotum is a solution for storing credit card information and creating charges against it.
It allow you to change between operators (Stripe, Paypal, etc) while keeping your customer credit cards in one place.

=head1 AUTHOR

Renato CRON E<lt>rentocron@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2015-2016 Renato CRON

Owing to http://eokoe.com

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Business::Payment> L<Business::OnlinePayment>

=cut
