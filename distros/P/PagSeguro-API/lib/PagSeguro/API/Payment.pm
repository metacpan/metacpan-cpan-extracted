package PagSeguro::API::Payment;
use Moo;

extends 'PagSeguro::API::Base';

use PagSeguro::API::Util;
use PagSeguro::API::Request;
use PagSeguro::API::Payment::Sender;

# attributes
has reference => (is => 'rw');
has redirect_url => (is => 'rw');
has notification_url => (is => 'rw');

# sender
has sender => (is => 'rw', default => sub{ PagSeguro::API::Payment::Sender->new });

# item list
has items => (is => 'rw', default => sub { [] });


# methods
sub item {
    my ($self, $id) = @_;
    do{ return $_ if $_->{id} eq $id } 
        for @{$self->items};
}

sub add_item {
    my $self = shift;
    my $args = (@_ % 2 == 0)? {@_} : undef;

    # required
    $args->{quantity} = 1 unless $args->{quantity};

    push @{$self->items}, $args;
}

sub request {
    my $self = shift;

    # build http post params
    my $params = $self->_build_params;

    my $req = PagSeguro::API::Request->new;
    my $res = $req->post(
        url     => $self->api_uri . '/checkout/',
        params  => $params
    );

    # parse response
    if($res && !$res->error){
        my $data = $res->data;
        my $result = $self->_parse_request($data);

        $res->data($result);
    }

    return $res;
}

sub request_form {
    my $self = shift;
    my $args = (@_ % 2 == 0)? {@_} : undef;

    # default button
    my $btn_name = delete $args->{text} || 'Checkout';
    $args->{type} = 'submit' unless $args->{type};


    # build http post params
    my $params = $self->_build_params;
    
    # remove sensitive data
    delete $params->{token};
    delete $params->{email};


    my $base_uri = $self->base_uri;
    my $html = qq{<form method="post" target="pagseguro"  action="$base_uri/v2/checkout/payment.html">\n};
    $html .= qq{<input type="hidden" name="$_" value="$params->{$_}" /> \n}
        for keys %$params;

    my $btn_params = join ' ', map { "$_=\"$args->{$_}\"" } keys %$args;
    $html .= qq{<button $btn_params>$btn_name</button>\n};
    $html .= qq{</form>};

    return $html;
}

sub _build_params {
    my $self = shift;

    # prapare parameters
    my $params = {};
    $params->{email} = $self->email;
    $params->{token} = $self->token;
    $params->{receiverEmail} = $self->email;

    # payment information
    $params->{reference}   = $self->reference;
    $params->{currency}    = 'BRL';

    $params->{redirectURL} = $self->redirect_url 
        if $self->redirect_url;

    $params->{notificationURL} = $self->notification_url 
        if $self->notification_url;

    # sender information
    if($self->sender){
        my $s = $self->sender;
        $params->{senderName}  = $s->name if $s->name;
        $params->{senderEmail} = $s->email if $s->email;
        $params->{senderPhone} = $s->phone if $s->phone;
        $params->{senderAreaCode} = $s->area_code if $s->area_code;
    }

    # items information
    my $c = 1;
    for my $i (@{$self->items}){
        map { my $k=camelize($_).$c;$params->{"item$k"}=$i->{$_} } keys %$i;
        $c++;
    }

    return $params;
}

sub _parse_request {
    my $self = shift;
    
    # read xml
    my $xml = $self->xml($_[0]) if $_[0];
    
    # getting /checkout/code
    my $code = $xml->find('/checkout/code')->string_value;
    my $date = $xml->find('/checkout/date')->string_value;

    return { 
        code => $code, 
        date => $date,
        payment_url => $self->base_uri . "/v2/checkout/payment.html?code=$code"
    };
}

1;
__END__
=encoding utf8

=head1 NAME

PagSeguro::API::Payment - Classe que implementa features de pagamento da API

=head1 SYNOPSIS

    use PagSeguro::API;

    # new instance
    my $p = PagSeguro::API->new;
    
    #configure
    $p->email('foo@bar.com');
    $p->token('95112EE828D94278BD394E91C4388F20');

    # new payment
    my $payment = $p->payment_request;
    $payment->reference('XXX');
    $payment->notification_url('http://google.com');
    $payment->redirect_url('http://url_of_love.com.br');

    $payment->add_item(
        id          => $product->id,
        description => $product->title,
        amount      => $product->price,
        weight      => $product->weight
    );

    my $response = $payment->request;

    # or by html form
    my $html_form = $payment->request_form;

    # error
    die "Error: ". $response->error if $response->error;

    my $data = $response->data;
    say $data->{payment_url};


=head1 DESCRIPTION

Esta classe implementa a parte de pagamento da API do PagSeguro.


=head1 AUTHOR

Daniel Vinciguerra <daniel.vinciguerra@bivee.com.br>

