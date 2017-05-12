package Net::Stripe::Simple;
$Net::Stripe::Simple::VERSION = '0.004';
# ABSTRACT: simple, non-Moose interface to the Stripe API

use v5.10;
use strict;
use warnings;

use Exporter qw(import);
use LWP::UserAgent;
use HTTP::Request::Common qw(GET POST DELETE);
use MIME::Base64 qw(encode_base64);
use URI::Escape qw(uri_escape);
use Scalar::Util qw(reftype blessed);
use JSON ();
use Devel::StackTrace;

use Net::Stripe::Simple::Data;
use Net::Stripe::Simple::Error;

our @EXPORT_OK = qw(true false null data_object);
our %EXPORT_TAGS = ( const => [qw(true false null)], all => \@EXPORT_OK );

use constant API_BASE => 'https://api.stripe.com/v1';

# version of stripe's API to use
our $STRIPE_VERSION = '2014-06-17';


sub new {
    my ( $class, $api, $version ) = @_;
    $class = ref($class) || $class;
    die 'API key required' unless $api;
    $version //= $STRIPE_VERSION;

    my $pkg_version = $Net::Stripe::Simple::VERSION // '0.01';

    my $ua = LWP::UserAgent->new;
    $ua->agent("$class/$pkg_version");
    my $auth = 'Basic ' . encode_base64( $api . ':' );
    bless { ua => $ua, auth => $auth, version => $version }, $class;
}

# API

# generic argument validation
sub _validate {
    my $self    = shift;
    my $name    = shift;
    my $actions = shift;
    my $action  = shift;
    ( my $err_name = $name ) =~ tr/_/ /;
    my $args = ref $_[0] eq 'HASH' ? $_[0] : { @_ == 1 ? ( id => $_[0] ) : @_ };
    die "$err_name action required" unless $action;
    die "unknown $err_name action: $action" unless exists $actions->{$action};
    my $method = $actions->{$action} //= $self->can("_${action}_$name");
    die "logic error: $action $err_name action not implemented" unless $method;
    return $args, $method;
}

# removes private keys from args
sub _clean {
    my $args = shift;
    delete @$args{ grep /^_/, keys %$args };
}

# generic implementations of these operations

sub _retrieve {
    my ( $self, $args ) = @_;
    my ( $base, $id )   = @$args{qw(_base id)};
    _invalid('No id provided.') unless defined $id;
    return $self->_get( $base . '/' . uri_escape($id) );
}

sub _update {
    my ( $self, $args ) = @_;
    my ( $base, $id )   = delete @$args{qw(_base id)};
    _invalid('No id provided.') unless defined $id;
    _clean($args);
    return $self->_post( $base . '/' . uri_escape($id), $args );
}

sub _create {
    my ( $self, $args ) = @_;
    my $base = delete $args->{_base};
    _clean($args);
    return $self->_post( $base, $args );
}

sub _list {
    my ( $self, $args ) = @_;
    my $base = delete $args->{_base};
    _clean($args);
    return $self->_get( $base, $args );
}

sub _del {
    my ( $self, $args ) = @_;
    my ( $base, $id )   = @$args{qw(_base id)};
    _invalid('No id provided.') unless defined $id;
    return $self->_delete( $base . '/' . uri_escape($id) );
}

# create a common uri base; expects customer id and sub-base
sub _customer_base {
    my $customer = shift;
    _invalid('No customer id provided.') unless defined $customer;
    return 'customers/' . uri_escape($customer) . '/' . shift;
}


sub charges {
    my $self = shift;
    state $actions =
      { map { $_ => undef } qw(create retrieve update refund capture list) };
    my ( $args, $method ) = $self->_validate( 'charge', $actions, @_ );
    $args->{_base} = 'charges';
    return $self->$method($args);
}
sub _create_charge   { goto &_create }
sub _retrieve_charge { goto &_retrieve }
sub _update_charge   { goto &_update }

sub _capture_charge {
    my ( $self, $args ) = @_;
    my ( $base, $id )   = delete @$args{qw(_base id)};
    _invalid('No id provided.') unless defined $id;
    _clean($args);
    return $self->_post( $base . '/' . uri_escape($id) . '/capture', $args );
}
sub _list_charge { goto &_list }

sub _refund_charge {
    my ( $self, $args ) = @_;
    my ( $base, $id )   = delete @$args{qw(_base id)};
    _invalid('No id provided.') unless defined $id;
    _clean($args);
    return $self->_post( $base . '/' . uri_escape($id) . '/refund', $args );
}


sub refunds {
    my $self = shift;
    state $actions = { map { $_ => undef } qw(create retrieve update list) };
    my ( $args, $method ) = $self->_validate( 'refund', $actions, @_ );
    $args->{_base} = 'charges';
    return $self->$method($args);
}

sub _create_refund {
    my ( $self, $args ) = @_;
    my ( $base, $id )   = delete @$args{qw(_base id)};
    _invalid('No id provided.') unless defined $id;
    _clean($args);
    return $self->_post( $base . '/' . uri_escape($id) . '/refunds', $args );
}

sub _retrieve_refund {
    my ( $self, $args ) = @_;
    my ( $base, $id, $charge ) = delete @$args{qw(_base id charge)};
    my @errors;
    push @errors, 'No id provided.'     unless defined $id;
    push @errors, 'No charge provided.' unless defined $charge;
    _invalid( join ' ', @errors ) if @errors;
    _clean($args);
    return $self->_get(
        $base . '/' . uri_escape($charge) . '/refunds/' . uri_escape($id),
        $args );
}

sub _update_refund {
    my ( $self, $args ) = @_;
    my ( $base, $id, $charge ) = delete @$args{qw(_base id charge)};
    my @errors;
    push @errors, 'No id provided.'     unless defined $id;
    push @errors, 'No charge provided.' unless defined $charge;
    _invalid( join ' ', @errors ) if @errors;
    _clean($args);
    return $self->_post(
        $base . '/' . uri_escape($charge) . '/refunds/' . uri_escape($id),
        $args );
}

sub _list_refund {
    my ( $self, $args ) = @_;
    my ( $base, $id )   = delete @$args{qw(_base id)};
    _invalid('No id provided.') unless defined $id;
    _clean($args);
    return $self->_get( $base . '/' . uri_escape($id) . '/refunds', $args );
}


sub customers {
    my $self = shift;
    state $actions =
      { map { $_ => undef } qw(create retrieve update delete list) };
    my ( $args, $method ) = $self->_validate( 'customer', $actions, @_ );
    $args->{_base} = 'customers';
    return $self->$method($args);
}
sub _create_customer   { goto &_create }
sub _retrieve_customer { goto &_retrieve }
sub _update_customer   { goto &_update }
sub _delete_customer   { goto &_del }
sub _list_customer     { goto &_list }


sub cards {
    my $self = shift;
    state $actions =
      { map { $_ => undef } qw(create retrieve update delete list) };
    my ( $args, $method ) = $self->_validate( 'card', $actions, @_ );
    $args->{_base} = 'cards';
    return $self->$method($args);
}

sub _create_card {
    my ( $self, $args ) = @_;
    my ( $base, $id, $customer ) = delete @$args{qw(_base id customer)};
    $id //= $customer;
    _clean($args);
    return $self->_post( _customer_base( $id, $base ), $args );
}

sub _retrieve_card {
    my ( $self, $args ) = @_;
    my ( $base, $id, $customer ) = @$args{qw(_base id customer)};
    my @errors;
    push @errors, 'No id provided.'          unless defined $id;
    push @errors, 'No customer id provided.' unless defined $customer;
    _invalid( join ' ', @errors ) if @errors;
    return $self->_get(
        _customer_base( $customer, $base ) . '/' . uri_escape($id) );
}

sub _update_card {
    my ( $self, $args ) = @_;
    my ( $base, $id, $customer ) = delete @$args{qw(_base id customer)};
    my @errors;
    push @errors, 'No id provided.'          unless defined $id;
    push @errors, 'No customer id provided.' unless defined $customer;
    _invalid( join ' ', @errors ) if @errors;
    _clean($args);
    return $self->_post(
        _customer_base( $customer, $base ) . '/' . uri_escape($id), $args );
}

sub _delete_card {
    my ( $self, $args ) = @_;
    my ( $base, $id, $customer ) = @$args{qw(_base id customer)};
    my @errors;
    push @errors, 'No id provided.'          unless defined $id;
    push @errors, 'No customer id provided.' unless defined $customer;
    _invalid( join ' ', @errors ) if @errors;
    return $self->_delete(
        _customer_base( $customer, $base ) . '/' . uri_escape($id) );
}

sub _list_card {
    my ( $self, $args ) = @_;
    my ( $base, $id, $customer ) = delete @$args{qw(_base id customer)};
    $id //= $customer;
    _clean($args);
    return $self->_get( _customer_base( $id, $base ), $args );
}


sub subscriptions {
    my $self = shift;
    state $actions =
      { map { $_ => undef } qw(create retrieve update cancel list) };
    my ( $args, $method ) = $self->_validate( 'subscription', $actions, @_ );
    $args->{_base} = 'subscriptions';
    return $self->$method($args);
}

sub _create_subscription {
    my ( $self, $args ) = @_;
    my ( $base, $id, $customer ) = delete @$args{qw(_base id customer)};
    $id //= $customer;
    _clean($args);
    return $self->_post( _customer_base( $id, $base ), $args );
}

sub _retrieve_subscription {
    my ( $self, $args ) = @_;
    my ( $base, $id, $customer ) = @$args{qw(_base id customer)};
    my @errors;
    push @errors, 'No id provided.'          unless defined $id;
    push @errors, 'No customer id provided.' unless defined $customer;
    _invalid( join ' ', @errors ) if @errors;
    return $self->_get(
        _customer_base( $customer, $base ) . '/' . uri_escape($id) );
}

sub _update_subscription {
    my ( $self, $args ) = @_;
    my ( $base, $id, $customer ) = delete @$args{qw(_base id customer)};
    my @errors;
    push @errors, 'No id provided.'          unless defined $id;
    push @errors, 'No customer id provided.' unless defined $customer;
    _invalid( join ' ', @errors ) if @errors;
    _clean($args);
    return $self->_post(
        _customer_base( $customer, $base ) . '/' . uri_escape($id), $args );
}

sub _cancel_subscription {
    my ( $self, $args ) = @_;
    my ( $base, $id, $customer ) = @$args{qw(_base id customer)};
    my @errors;
    push @errors, 'No id provided.'          unless defined $id;
    push @errors, 'No customer id provided.' unless defined $customer;
    _invalid( join ' ', @errors ) if @errors;
    return $self->_delete(
        _customer_base( $customer, $base ) . '/' . uri_escape($id) );
}

sub _list_subscription {
    my ( $self, $args ) = @_;
    my ( $base, $id, $customer ) = delete @$args{qw(_base id customer)};
    $id //= $customer;
    _clean($args);
    return $self->_get( _customer_base( $id, $base ), $args );
}


sub plans {
    my $self = shift;
    state $actions =
      { map { $_ => undef } qw(create retrieve update delete list) };
    my ( $args, $method ) = $self->_validate( 'plan', $actions, @_ );
    $args->{_base} = 'plans';
    return $self->$method($args);
}
sub _create_plan   { goto &_create }
sub _retrieve_plan { goto &_retrieve }
sub _update_plan   { goto &_update }
sub _delete_plan   { goto &_del }
sub _list_plan     { goto &_list }


sub coupons {
    my $self = shift;
    state $actions = { map { $_ => undef } qw(create retrieve delete list) };
    my ( $args, $method ) = $self->_validate( 'coupon', $actions, @_ );
    $args->{_base} = 'coupons';
    return $self->$method($args);
}
sub _create_coupon   { goto &_create }
sub _retrieve_coupon { goto &_retrieve }
sub _delete_coupon   { goto &_del }
sub _list_coupon     { goto &_list }


sub discounts {
    my $self = shift;
    state $actions = { map { $_ => undef } qw(customer subscription) };
    my ( $args, $method ) = $self->_validate( 'discount', $actions, @_ );
    return $self->$method($args);
}

sub _customer_discount {
    my ( $self, $args ) = @_;
    my ( $id, $customer ) = @$args{qw(id customer)};
    $id //= $customer;
    return $self->_delete( _customer_base( $id, 'discount' ) );
}

sub _subscription_discount {
    my ( $self, $args ) = @_;
    my ( $id, $customer ) = @$args{qw(subscription customer)};
    my @errors;
    push @errors, 'No id provided.'          unless defined $id;
    push @errors, 'No customer id provided.' unless defined $customer;
    _invalid( join ' ', @errors ) if @errors;
    my $path =
        _customer_base( $customer, 'subscriptions' ) . '/'
      . uri_escape($id)
      . '/discount';
    return $self->_delete($path);
}


sub invoices {
    my $self = shift;
    state $actions =
      { map { $_ => undef }
          qw(create retrieve lines update pay list upcoming) };
    my ( $args, $method ) = $self->_validate( 'invoice', $actions, @_ );
    $args->{_base} = 'invoices';
    return $self->$method($args);
}
sub _create_invoice   { goto &_create }
sub _retrieve_invoice { goto &_retrieve }

sub _lines_invoice {
    my ( $self, $args ) = @_;
    my ( $base, $id )   = delete @$args{qw(_base id)};
    _invalid('No id provided.') unless defined $id;
    _clean($args);
    return $self->_get( $base . '/' . uri_escape($id) . '/lines', $args );
}
sub _update_invoice { goto &_update }

sub _pay_invoice {
    my ( $self, $args ) = @_;
    my ( $base, $id )   = @$args{qw(_base id)};
    _invalid('No id provided.') unless defined $id;
    return $self->_post( $base . '/' . uri_escape($id) . '/pay' );
}
sub _list_invoice { goto &_list }

sub _upcoming_invoice {
    my ( $self, $args ) = @_;
    my ( $base, $id, $customer ) = @$args{qw(_base id customer)};
    $id //= $customer;
    _invalid('No id provided.') unless defined $id;
    return $self->_get( $base . '/upcoming', { customer => $id } );
}


sub invoice_items {
    my $self = shift;
    state $actions =
      { map { $_ => undef } qw(create retrieve update delete list) };
    my ( $args, $method ) = $self->_validate( 'invoice_item', $actions, @_ );
    $args->{_base} = 'invoiceitems';
    return $self->$method($args);
}
sub _create_invoice_item   { goto &_create }
sub _retrieve_invoice_item { goto &_retrieve }
sub _update_invoice_item   { goto &_update }
sub _delete_invoice_item   { goto &_del }
sub _list_invoice_item     { goto &_list }


sub disputes {
    my $self = shift;
    state $actions = { map { $_ => undef } qw(update close) };
    my ( $args, $method ) = $self->_validate( 'dispute', $actions, @_ );
    return $self->$method($args);
}

sub _update_dispute {
    my ( $self, $args ) = @_;
    my $id = delete $args->{id};
    _invalid('No id provided.') unless defined $id;
    _clean($args);
    my $path = 'charges/' . uri_escape($id) . '/dispute';
    return $self->_post( $path, $args );
}

sub _close_dispute {
    my ( $self, $args ) = @_;
    my $id = delete $args->{id};
    _invalid('No id provided.') unless defined $id;
    _clean($args);
    my $path = 'charges/' . uri_escape($id) . '/dispute/close';
    return $self->_post( $path, $args );
}


sub transfers {
    my $self = shift;
    state $actions =
      { map { $_ => undef } qw(create retrieve update cancel list) };
    my ( $args, $method ) = $self->_validate( 'transfer', $actions, @_ );
    $args->{_base} = 'transfers';
    return $self->$method($args);
}
sub _create_transfer   { goto &_create }
sub _retrieve_transfer { goto &_retrieve }
sub _update_transfer   { goto &_update }

sub _cancel_transfer {
    my ( $self, $args ) = @_;
    my ( $base, $id )   = @$args{qw(_base id)};
    _invalid('No id provided.') unless defined $id;
    my $path = $base . '/' . uri_escape($id) . '/cancel';
    return $self->_post($path);
}
sub _list_transfer { goto &_list }


sub recipients {
    my $self = shift;
    state $actions =
      { map { $_ => undef } qw(create retrieve update delete list) };
    my ( $args, $method ) = $self->_validate( 'recipient', $actions, @_ );
    $args->{_base} = 'recipients';
    return $self->$method($args);
}
sub _create_recipient   { goto &_create }
sub _retrieve_recipient { goto &_retrieve }
sub _update_recipient   { goto &_update }
sub _delete_recipient   { goto &_del }
sub _list_recipient     { goto &_list }


sub application_fees {
    my $self = shift;
    state $actions = { map { $_ => undef } qw(retrieve refund list) };
    my ( $args, $method ) = $self->_validate( 'application_fee', $actions, @_ );
    $args->{_base} = 'application_fees';
    return $self->$method($args);
}

sub _retrieve_application_fee { goto &_retrieve }
sub _list_application_fee     { goto &_list }

sub _refund_application_fee {
    my ( $self, $args ) = @_;
    my ( $base, $id )   = delete @$args{qw(_base id)};
    _invalid('No id provided.') unless defined $id;
    _clean($args);
    my $path = $base . '/' . uri_escape($id) . '/refund';
    return $self->_post( $path, $args );
}


sub account {
    my $self = shift;
    unshift @_, 'retrieve' unless @_;
    state $actions = { map { $_ => undef } qw(retrieve) };
    my ( $args, $method ) = $self->_validate( 'account', $actions, @_ );
    $args->{_base} = 'account';
    return $self->$method($args);
}

sub _retrieve_account {
    my ( $self, $args ) = @_;
    my $base = $args->{_base};
    return $self->_get($base);
}


sub balance {
    my $self = shift;
    state $actions = { map { $_ => undef } qw(retrieve history transaction) };
    my ( $args, $method ) = $self->_validate( 'balance', $actions, @_ );
    $args->{_base} = 'balance';
    return $self->$method($args);
}
sub _retrieve_balance {
    my ( $self, $args ) = @_;
    return $self->_get( $args->{_base} );
}

sub _transaction_balance {
    my ( $self, $args ) = @_;
    my ( $base, $id )   = @$args{qw(_base id)};
    _invalid('No id provided.') unless defined $id;
    my $path = $base . '/history/' . uri_escape($id);
    return $self->_get($path);
}

sub _history_balance {
    my ( $self, $args ) = @_;
    my $base = delete $args->{_base};
    _clean($args);
    my $path = $base . '/history';
    return $self->_get( $path, $args );
}


sub events {
    my $self = shift;
    state $actions = { map { $_ => undef } qw(retrieve list) };
    my ( $args, $method ) = $self->_validate( 'event', $actions, @_ );
    $args->{_base} = 'events';
    return $self->$method($args);
}
sub _retrieve_event { goto &_retrieve }
sub _list_event     { goto &_list }


sub tokens {
    my $self = shift;
    state $actions = { map { $_ => undef } qw(create retrieve bank) };
    my ( $args, $method ) = $self->_validate( 'token', $actions, @_ );
    $args->{_base} = 'tokens';
    return $self->$method($args);
}
sub _create_token   { goto &_create }
sub _retrieve_token { goto &_retrieve }
sub _bank_token     { goto &_create }

# Helper methods copied with modification from Net::Stripe

sub _get {
    my ( $self, $path, $args ) = @_;
    $path .= '?' . _encode_params($args) if $args && %$args;
    my $req = GET API_BASE . '/' . $path;
    return $self->_make_request($req);
}

# implements PHP convention for encoding "dictionaries" (why don't they accept
# json bodies in posts?)
sub _encode_params {
    my $args = shift;
    my @components;
    for my $key ( keys %$args ) {
        my $ek    = uri_escape($key);
        my $value = $args->{$key};
        if (   blessed $value
            && $value->isa('Net::Stripe::Simple::Data')
            && exists $value->{id} )
        {
            push @components, $ek . '=' . $value->{id};
            next;
        }

        my $ref = ref($value);
        if ($ref eq 'HASH') {
            for my $sk ( keys %$value ) {
                my $sv = $value->{$sk};
                next
                  if ref $sv;  # don't think this PHP convention goes deeper
                push @components,
                  $ek . '[' . uri_escape($sk) . ']=' . uri_escape($sv);
            }
        } elsif ($ref eq 'ARRAY') {
            for my $sv (@$value) {
                next if ref $sv;    # again, I think we can't go deeper
                push @components, $ek . '[]=' . uri_escape($sv);
            }
        } else {
            $value =    # JSON boolean stringification magic has been erased
              ref $value eq 'JSON::PP::Boolean'
              ? $value
                  ? 'true'
                  : 'false'
              : uri_escape($value);
            push @components, "$ek=$value"
        }
    }
    return join( '&', @components );
}

sub _delete {
    my ( $self, $path, $args ) = @_;
    $path .= '?' . _encode_params($args) if $args && %$args;
    my $req = DELETE API_BASE . '/' . $path;
    return $self->_make_request($req);
}

sub _post {
    my ( $self, $path, $obj ) = @_;

    my $req = POST API_BASE . '/' . $path,
      ( $obj ? ( Content => _encode_params($obj) ) : () );
    return $self->_make_request($req);
}

sub _make_request {
    my ( $self, $req ) = @_;
    my ( $e, $resp, $ret );
    state $json = do {
        my $j = JSON->new;
        $j->utf8(1);
        $j;
    };
    eval {
        $req->header( Authorization  => $self->{auth} );
        $req->header( Stripe_Version => $self->{version} );

        $resp = $self->{ua}->request($req);
        if ( $resp->code == 200 ) {
            my $hash = $json->decode( $resp->content );
            $ret = data_object($hash);
        }
        else {
            if ( $resp->header('Content_Type') =~ m{text/html} ) {
                $e = _hash_to_error(
                    code    => $resp->code,
                    type    => $resp->message,
                    message => $resp->message
                );
            }
            else {
                my $hash = $json->decode( $resp->content );
                $e = _hash_to_error( $hash->{error} // $hash );
            }
        }
    };
    if ($@) {
        $e = _hash_to_error(
            {
                type => "Could not decode HTTP response: $@",
                $resp
                ? ( message => $resp->status_line . " - " . $resp->content )
                : (),
            }
        );
    }
    die $e if $e;
    return $ret if $ret;
    die _hash_to_error();
}

# generates validation error when parameters required to construct the URL
# have not been provided
sub _invalid {
    my $message = shift;
    my %params = ( type => 'Required parameter missing' );
    $params{message} = $message if defined $message;
    die _hash_to_error(%params);
}


sub data_object {
    my $ref = shift;
    my $rr  = ref $ref;
    return unless $rr;
    die "forbidden class: $rr" if blessed($ref) and $rr !~ /^JSON::/;
    bless $ref, 'Net::Stripe::Simple::Data' if $rr eq 'HASH';

    if ($rr eq 'HASH') {
        data_object($_) for values %$ref
    } elsif ($rr eq 'ARRAY') {
        data_object($_) for @$ref
    }

    return $ref;
}

sub _hash_to_error {
    my %args  = ( ref $_[0] ? %{ $_[0] } : @_ );
    my $o     = data_object( \%args );
    my $trace = Devel::StackTrace->new( ignore_package => __PACKAGE__ );
    $o->{_trace} = $trace;
    bless $o, 'Net::Stripe::Simple::Error';
}


sub true()  { JSON::true }
sub false() { JSON::false }
sub null()  { JSON::null }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Stripe::Simple - simple, non-Moose interface to the Stripe API

=head1 VERSION

version 0.004

=head1 SYNOPSIS

  use Net::Stripe::Simple;

  my $stripe = Net::Stripe::Simple->new('sk_test_00000000000000000000000000');

  # when the only argument is an id, that's all you need
  my $c1 = $stripe->customers( retrieve => 'cus_meFAKEfakeFAKE' );

  # you can provide arguments as a hash reference
  my $c2 = $stripe->customers( retrieve => { id => 'cus_ImFAKEfakeFAKE' } );

  # or as key-value list
  my $c3 = $stripe->customers( 'retrieve', id => 'cus_I2FAKEfakeFAKE', expand => 1 );

=head1 DESCRIPTION

A lightweight, limited-dependency client to the stripe.com API. This is just
a thin wrapper around stripe's RESTful API. It is "simple" in the sense that it
is simple to write and maintain and it maps simply onto Stripe's web
documentation, so it is simple to use. When you get a response back, it's just
the raw JSON blessed with some convenience methods: stringification to ids and
autoloaded attributes (L<Net::Stripe::Simple::Data>). If there is an error, the
error that is thrown is again just Stripe's JSON with a little blessing
(L<Net::Stripe::Simple::Error>).

This simplicity comes at a cost: L<Net::Stripe::Simple> does not
validate your parameters aside from those required to construct the URL before
constructing a request and sending it off to Stripe. This means that if you've
done it wrong it takes a round trip to find out.

For the full details of stripe's API, see L<https://stripe.com/docs/api>.

=head2 Method Invocation

Following the organization scheme of Stripe's API, actions are grouped by entity
type, each entity corresponding to a method. For a given method there are
generally a number of actions, which are treated as the primary key in a
parameter hash. Parameters for these actions are provided by a parameter hash
which is the value of the primary key. However, there is some flexibility.

Methods that require only an id are flexible. All the following will work:

  $stripe->plans( retrieve => { id => $id } );
  $stripe->plans( 'retrieve', id => $id );
  $stripe->plans( retrieve => $id );

Methods that require no arguments are also flexible:

  $stripe->plans( list => { } );
  $stripe->plans('list');

=head2 Export Tags

L<Net::Stripe::Simple> exports nothing by default. It has four exportable
constants and one exportable function:

=over 4

=item true

=item false

=item null

=item data_object

=back

To facilitate their export, it has two tags:

=over 4

=item :const

The three constants.

=item :all

The three constants plus C<data_object>.

=back

=head1 NAME

Net::Stripe::Simple - simple, non-Moose interface to the Stripe API

=head1 METHODS

=head2 new

  Net::Stripe::Simple->('sk_test_00000000000000000000000000', '2014-01-31')

The class constructor method. The API key is required. The version date is
optional. If not supplied, the value of C<$Net::Stripe::Simple::STRIPE_VERSION>
will be supplied. L<Net::Stripe::Simple> was implemented or has been updated
for the following versions:

=over 4

=item 2014-01-31

=item 2014-06-17

=back

The default version will always be the most recent version whose handling
required an update to L<Net::Stripe::Simple>.

=head2 charges

See L<https://stripe.com/docs/api#charges>.

B<Available Actions>

=over 4

=item create

    $charge = $stripe->charges(
        create => {
            customer => $customer,
            amount   => 100,
            currency => 'usd',
            capture  => 'false',
        }
    );

=item retrieve

    $charge = $stripe->charges( retrieve => $id );

=item update

    $charge = $stripe->charges(
        update => {
            id          => $charge,
            description => 'foo',
        }
    );

=item refund

Availability may depend on version of API.
    $charge = $stripe->charges( refund => $id );

=item capture

    $charge = $stripe->charges( capture => $id );

=item list

    my $charges = $stripe->charges('list');

=back

=head2 refunds

See L<https://stripe.com/docs/api#refunds>.

B<Available Actions>

=over 4

=item create

    my $refund = $stripe->refunds(
        create => {
            id     => $charge,
            amount => 50
        }
    );

=item retrieve

    $refund = $stripe->refunds(
        retrieve => {
            id     => $refund,
            charge => $charge
        }
    );

=item update

    $refund = $stripe->refunds(
        update => {
            id       => $refund,
            charge   => $charge,
            metadata => { foo => 'bar' }
        }
    );

=item list

    my $refunds = $stripe->refunds( list => $charge );

=back

=head2 customers

See L<https://stripe.com/docs/api#customers>.

B<Available Actions>

=over 4

=item create

    $customer = $stripe->customers(
        create => {
            metadata => { foo => 'bar' }
        }
    );

=item retrieve

    $customer = $stripe->customers( retrieve => $id );

=item update

    $customer = $stripe->customers(
        update => {
            id       => $customer,
            metadata => { foo => 'baz' }
        }
    );

=item delete

    $customer = $stripe->customers( delete => $id );

=item list

    my $customers = $stripe->customers(
        list => {
            created => { gte => $time - 100 }
        }
    );

=back

=head2 cards

See L<https://stripe.com/docs/api#cards>.

B<Available Actions>

=over 4

=item create

    $card = $stripe->cards(
        create => {
            customer => $customer,
            card     => {
                number    => '4242424242424242',
                exp_month => $expiry->month,
                exp_year  => $expiry->year,
                cvc       => 123
            }
        }
    );

=item retrieve

    $card = $stripe->cards(
        retrieve => {
            customer => $customer,
            id       => $id
        }
    );

=item update

    $card = $stripe->cards(
        update => {
            customer => $customer,
            id       => $card,
            name     => 'foo',
        }
    );

=item delete

    $card = $stripe->cards(
        delete => {
            customer => $customer,
            id       => $id
        }
    );

=item list

    my $cards = $stripe->cards( list => $customer );

=back

=head2 subscriptions

See L<https://stripe.com/docs/api#subscriptions>.

B<Available Actions>

=over 4

=item create

    $subscription = $stripe->subscriptions(
        create => {
            customer => $customer,
            plan     => $plan,
        }
    );

=item retrieve

    $subscription = $stripe->subscriptions(
        retrieve => {
            id       => $id,
            customer => $customer,
        }
    );

=item update

    $subscription = $stripe->subscriptions(
        update => {
            id       => $id,
            customer => $customer,
            metadata => { foo => 'bar' }
        }
    );

=item cancel

    $subscription = $stripe->subscriptions(
        cancel => {
            id       => $id,
            customer => $customer,
        }
    );

=item list

    my $subscriptions = $stripe->subscriptions( list => $customer );

=back

=head2 plans

See L<https://stripe.com/docs/api#plans>.

B<Available Actions>

=over 4

=item create

    $plan = $stripe->plans(
        create => {
            id       => $id,
            amount   => 100,
            currency => 'usd',
            interval => 'week',
            name     => 'Foo',
        }
    );

=item retrieve

    $plan = $stripe->plans( retrieve => $id );

=item update

    $plan = $stripe->plans(
        update => {
            id       => $id,
            metadata => { bar => 'baz' }
        }
    );

=item delete

    $plan = $stripe->plans( delete => $id );

=item list

    my $plans = $stripe->plans('list');

=back

=head2 coupons

B<Available Actions>

See L<https://stripe.com/docs/api#coupons>.

=over 4

=item create

    $coupon = $stripe->coupons(
        create => {
            percent_off => 1,
            duration    => 'forever',
        }
    );

=item retrieve

    $coupon = $stripe->coupons( retrieve => $id );

=item delete

    $coupon = $stripe->coupons( delete => $coupon );

=item list

    my $coupons = $stripe->coupons('list');

=back

=head2 discounts

See L<https://stripe.com/docs/api#discounts>.

B<Available Actions>

=over 4

=item customer

    my $deleted = $stripe->discounts( customer => $c );

=item subscription

    $deleted = $stripe->discounts(
        subscription => {
            customer     => $c,
            subscription => $s,
        }
    );

=back

=head2 invoices

See L<https://stripe.com/docs/api#invoices>.

B<Available Actions>

=over 4

=item create

    my $new_invoice = $stripe->invoices(
        create => {
            customer => $customer,
        }
    );

=item retrieve

    $invoice = $stripe->invoices( retrieve => $id );

=item lines

    my $lines = $stripe->invoices( lines => $invoice );

=item update

    $stripe->subscriptions(
        update => {
            customer => $customer,
            id       => $subscription,
            plan     => $spare_plan,
        }
    );

=item pay

    $new_invoice = $stripe->invoices( pay => $new_invoice );

=item list

    my $invoices = $stripe->invoices( list => { customer => $customer } );

=item upcoming

    $new_invoice = $stripe->invoices( upcoming => $customer );

=back

=head2 invoice_items

See L<https://stripe.com/docs/api#invoiceitems>.

B<Available Actions>

=over 4

=item create

    my $item = $stripe->invoice_items(
        create => {
            customer => $customer,
            amount   => 100,
            currency => 'usd',
            metadata => { foo => 'bar' }
        }
    );

=item retrieve

    $item = $stripe->invoice_items( retrieve => $id );

=item update

    $item = $stripe->invoice_items(
        update => {
            id       => $item,
            metadata => { foo => 'baz' }
        }
    );

=item delete

    $item = $stripe->invoice_items( delete => $item );

=item list

    my $items = $stripe->invoice_items( list => { customer => $customer } );

=back

=head2 disputes

See L<https://stripe.com/docs/api#disputes>.

B<Available Actions>

=over 4

=item update

    $stripe->disputes(
        update => {
            id       => $charge,
            metadata => { foo => 'bar' }
        }
    );

=item close

    $stripe->disputes( close => $charge );

=back

=head2 transfers

See L<https://stripe.com/docs/api#transfers>.

B<Available Actions>

=over 4

=item create

    my $transfer = $stripe->transfers(
        create => {
            amount    => 1,
            currency  => 'usd',
            recipient => $recipient,
        }
    );

=item retrieve

    $transfer = $stripe->transfers( retrieve => $id );

=item update

    $transfer = $stripe->transfers(
        update => {
            id       => $transfer,
            metadata => { foo => 'bar' }
        }
    );

=item cancel

    $transfer = $stripe->transfers( cancel => $transfer );

=item list

    my $transfers = $stripe->transfers(
        list => {
            created => { gt => $time }
        }
    );

=back

=head2 recipients

See L<https://stripe.com/docs/api#recipients>.

B<Available Actions>

=over 4

=item create

    $recipient = $stripe->recipients(
        create => {
            name => 'I Am An Example',
            type => 'individual',
        }
    );

=item retrieve

    $recipient = $stripe->recipients( retrieve => $id );

=item update

    $recipient = $stripe->recipients(
        update => {
            id       => $recipient,
            metadata => { foo => 'bar' },
        }
    );

=item delete

    $recipient = $stripe->recipients( delete => $id );

=item list

    my $recipients = $stripe->recipients('list');

=back

=head2 application_fees

See L<https://stripe.com/docs/api#application_fees>.

B<Available Actions>

=over 4

=item retrieve

    my $fee = $stripe->application_fees( retrieve => $id );

=item refund

    my $fee = $stripe->application_fees( refund => $id );

=item list

    my $fees = $stripe->application_fees('list');

=back

=head2 account

See L<https://stripe.com/docs/api#account>.

B<Available Actions>

=over 4

=item retrieve

    my $account = $stripe->account('retrieve');  # or
    $account = $stripe->account;

=back

=head2 balance

See L<https://stripe.com/docs/api#balance>.

B<Available Actions>

=over 4

=item retrieve

    my $balance = $stripe->balance('retrieve');

=item history

    my $history = $stripe->balance('history');

=item transaction

    $balance = $stripe->balance( transaction => $charge );

=back

=head2 events

See L<https://stripe.com/docs/api#events>.

B<Available Actions>

=over 4

=item retrieve

    $event = $stripe->events( retrieve => $id );

=item list

    my $events = $stripe->events( list => { created => { gt => $time } } );

=back

=head2 tokens

See L<https://stripe.com/docs/api#tokens>.

B<Available Actions>

=over 4

=item create

    $token = $stripe->tokens(
        create => {
            card => {
                number    => '4242424242424242',
                exp_month => $expiry->month,
                exp_year  => $expiry->year,
                cvc       => 123
            }
        }
    );
    $token = $stripe->tokens(
        create => {
            bank_account => {
                country        => 'US',
                routing_number => '110000000',
                account_number => '000123456789',
            }
        }
    );

=item retrieve

    $token = $stripe->tokens( retrieve => $id );

=item bank

To preserve the parallel with the Stripe's API documentation, there is a
special "bank" action, but it is simply a synonym for the code above.
    $token = $stripe->tokens(
        bank => {
            bank_account => {
                country        => 'US',
                routing_number => '110000000',
                account_number => '000123456789',
            }
        }
    );

=back

=head1 FUNCTIONS

=head2 data_object($hash_ref)

This function recursively converts a hash ref into a data object. This is just
L<Net::Stripe::Simple::Data>, whose only function is to autoload accessors for
all the keys in the hash. It is made for adding magic to JSON objects. If you
try to give it something that contains blessed references whose class is
outside the JSON namespace it will die.

=head1 SEE ALSO

L<Net::Stripe>, L<Business::Stripe>

=head1 EXPORTED CONSTANTS

These are just the corresponding L<JSON> constants. They are exported by
L<Net::Stripe::Simple> for convenience.

  use Net::Stripe::Simple qw(:const);
  ...
  my $subscription = $stripe->subscriptions(
      update => {
          id       => $id,
          customer => $customer_id,
          plan     => $plan_id,
          prorate  => true,
      }
  );

You can import the constants individually or all together with C<:const>.

=over 4

=item true

=item false

=item null

=back

=head1 AUTHORS

=over 4

=item *

Grant Street Group <developers@grantstreet.com>

=item *

David F. Houghton <dfhoughton@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Grant Street Group.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 AUTHORS

=over 4

=item *

Grant Street Group <developers@grantstreet.com>

=item *

David F. Houghton <dfhoughton@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Grant Street Group.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
