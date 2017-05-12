package SilverGoldBull::API;

use strict;
use warnings;

use Mouse;

use Carp qw(croak);
use LWP::UserAgent;
use HTTP::Request;
use HTTP::Headers;
use URI;
use JSON::XS;

use SilverGoldBull::API::Response;

use constant {
  API_URL           => 'https://api.silvergoldbull.com/',
  JSON_CONTENT_TYPE => 'application/json',
  TIMEOUT           => 10,
};

=head1 NAME

SilverGoldBull::API - Perl client for the SilverGoldBull(https://silvergoldbull.com/) web service

=head1 VERSION

Version 0.08

=cut

our $VERSION = '0.08';

has 'ua' => (
  is       => 'ro',
  init_arg => undef,
  isa      => 'LWP::UserAgent',
  default  => sub {
    return LWP::UserAgent->new();
  }
);

has 'json' => (
  is       => 'ro',
  init_arg => undef,
  isa      => 'JSON::XS',
  default  => sub {
    return JSON::XS->new();
  }
);

has 'api_url' => ( is => 'rw', isa => 'Str',        default => sub { return API_URL; } );
has 'api_key' => ( is => 'rw', isa => 'Maybe[Str]', default => sub { return $ENV{SILVERGOLDBULL_API_KEY}; } );
has 'version' => ( is => 'rw', isa => 'Int',        default => sub { return 1; } );
has 'timeout' => ( is => 'rw', isa => 'Int',        default => sub { return TIMEOUT } );

sub BUILD {
  my ($self) = @_;

  if (!$self->api_key) {
    croak("API key is missing. Specify 'api_key' parameter or set 'SILVERGOLDBULL_API_KEY' variable environment.");
  }
}

sub _build_url {
  my ($self, @params) = @_;
  my $version = $self->version;
  my $url_params = join('/', qq{v$version}, @params);

  return URI->new_abs($url_params, $self->api_url)->as_string;
}

sub _request {
  my ($self, $args) = @_;
  my %params = (
    'X-API-KEY' => $self->api_key,
    %{$args->{params} || {}},
  );
  
  my $head = HTTP::Headers->new(Content_Type => JSON_CONTENT_TYPE);
  $head->header(%params);
  my $req  = HTTP::Request->new($args->{method},$args->{url},$head);
  my $response = $self->ua->request($req);
  my $content  = $response->content;
  my $success  = $response->is_success;
  my $data     = undef;
  
  if ($response->headers->content_type =~ m/${\JSON_CONTENT_TYPE}/i) {
    eval {
      $data = $self->{json}->decode($content);
    };
    if ($@) {
      croak('Internal server error');
    }
  }
  else {
    $data = $content;
  }
  
  return SilverGoldBull::API::Response->new({ success => $success || 0, data => $data });
}

=head1 SYNOPSIS

    use SilverGoldBull::API;
    use SilverGoldBull::API::BillingAddress;
    use SilverGoldBull::API::ShippingAddress;
    use SilverGoldBull::API::Item;
    use SilverGoldBull::API::Order;

    my $sgb = SilverGoldBull::API->new(api_key => <API_KEY>);#or use SILVERGOLDBULL_API_KEY env variable
    
    #get available currency list
    my $response = $sgb->get_currency_list();
    if ($response->is_success) {
        my $currency_list = $response->data();
    }
    
    my $billing_addr = SilverGoldBull::API::BillingAddress->new({
      'city'       => 'Calgary',
      'first_name' => 'John',
      'region'     => 'AB',
      'email'      => 'sales@silvergoldbull.com',
      'last_name'  => 'Smith',
      'postcode'   => 'T2P 5C5',
      'street'     => '888 - 3 ST SW, 10 FLOOR - WEST TOWER',
      'phone'      => '+1 (403) 668 8648',
      'country'    => 'CA'
    });
    
    my $shipping_addr = SilverGoldBull::API::ShippinggAddress->new({
      'city'       => 'Calgary',
      'first_name' => 'John',
      'region'     => 'AB',
      'email'      => 'sales@silvergoldbull.com',
      'last_name'  => 'Smith',
      'postcode'   => 'T2P 5C5',
      'street'     => '888 - 3 ST SW, 10 FLOOR - WEST TOWER',
      'phone'      => '+1 (403) 668 8648',
      'country'    => 'CA'
    });
    
    my $item = SilverGoldBull::API::Item->new({
        'bid_price' => 468.37,
        'qty'       => 1,
        'id'        => '2706',
    });
    
    my $order_info = {
      "currency"        => "USD",
      "declaration"     => "TEST",
      "shipping_method" => "1YR_STORAGE",
      "payment_method"  => "paypal",
      "shipping"        => $shipping,#or raw hashref
      "billing"         => $billing,#or raw hashref
      "items"           => [$item],#or raw array of hashrefs
    };
    my $order = SilverGoldBull::API::Order->new($order_info);
    my $response = $sgb->create_order($order);

=head1 SUBROUTINES/METHODS

=head2 get_currency_list

This method returns an available currencies.

Input: nothing

Result: SilverGoldBull::API::Response object

=cut

sub get_currency_list {
  my ($self) = @_;

  return $self->_request({ method => 'GET', url => $self->_build_url('currencies') });
}

=head2 get_payment_method_list

This method returns an available payment methods.

Input: nothing

Result: SilverGoldBull::API::Response object

=cut

sub get_payment_method_list {
  my ($self) = @_;
  return $self->_request({ method => 'GET', url => $self->_build_url('payments/method') });
}

=head2 get_shipping_method_list

This method returns an available shipping methods.

Input: nothing

Result: SilverGoldBull::API::Response object

=cut

sub get_shipping_method_list {
  my ($self) = @_;
  return $self->_request({ method => 'GET', url => $self->_build_url('shipping/method') });
}

=head2 get_product_list

This method returns product list.

Input: nothing

Result: SilverGoldBull::API::Response object

=cut

sub get_product_list {
  my ($self) = @_;
  return $self->_request({ method => 'GET', url => $self->_build_url('products') });
}

=head2 get_product

This method returns detailed information about product by id.

Input: product id

Result: SilverGoldBull::API::Response object

=cut

sub get_product {
  my ($self, $id) = @_;
  return $self->_request({ method => 'GET', url => $self->_build_url('products', $id) });
}

=head2 get_order_list

This method returns order list.

Input: nothing

Result: SilverGoldBull::API::Response object

=cut

sub get_order_list {
  my ($self) = @_;
  return $self->_request({ method => 'GET', url => $self->_build_url('orders') });
}

=head2 get_order

This method returns detailed information about order by id.

Input: order id;

Result: SilverGoldBull::API::Response object

=cut

sub get_order {
  my ($self, $id) = @_;
  if (!defined $id) {
    croak('Missing order id');
  }

  return $self->_request({ method => 'GET', url => $self->_build_url('orders', $id) });
}

=head2 create_order

This method creates a new order.

Input: SilverGoldBull::API::Order object

Result: SilverGoldBull::API::Response object

=cut

sub create_order {
  my ($self, $order) = @_;
  if (!defined $order && (ref($order) ne 'SilverGoldBull::API::Order')) {
    croak('Missing SilverGoldBull::API::Order object');
  }

  return $self->_request({ method => 'POST', url => $self->_build_url('orders/create'), params => $order->to_hashref });
}

=head2 create_quote

This method creates a quote.

Input: SilverGoldBull::API::Quote object

Result: SilverGoldBull::API::Response object

=cut

sub create_quote {
  my ($self, $quote) = @_;
  if (!defined $quote && (ref($quote) ne 'SilverGoldBull::API::Quote')) {
    croak('Missing SilverGoldBull::API::Quote object');
  }

  return $self->_request({ method => 'POST', url => $self->_build_url('orders/quote'), params => $quote->to_hashref });
}

=head1 AUTHOR

Denis Boyun, C<< <denisboyun at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-silvergoldbull-api at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SilverGoldBull-API>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SilverGoldBull::API


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SilverGoldBull-API>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SilverGoldBull-API>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SilverGoldBull-API>

=item * Search CPAN

L<http://search.cpan.org/dist/SilverGoldBull-API/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2016 Denis Boyun.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.


=cut

1; # End of SilverGoldBull::API
