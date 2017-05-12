package PagSeguro::API::Transaction;
use Moo;

extends 'PagSeguro::API::Base';

use Carp;
use PagSeguro::API::Util;
use PagSeguro::API::Request;

# attributes
has code => (is => 'rw');

sub by_code {
    my ($self, $code) = (shift, shift);
    my $args = (@_ % 2 == 0)? {@_} : undef;

    croak "error: code cannot be null!" unless $code;

    my $email = $self->email;
    my $token = $self->token;

    my $req = PagSeguro::API::Request->new;
    my $uri = $self->api_uri . "/transactions/${code}?email=${email}&token=${token}";
    
    # is notification
    $uri = $self->api_uri . "/transactions/notifications/${code}?email=${email}&token=${token}"
        if $args->{notification};

    # api response
    my $res = $req->get(url => $uri);

    if($res && !$res->error){
        my $result = $self->_parse_transaction($res->data);
        $res->data($result);
    }
    
    return $res;
}

sub by_notification_code {
    my ($self, $code) = (shift, shift);
    return $self->by_code($code, notification => 1);
}

sub _parse_transaction {
    my $self = shift;
    
    # read xml
    my $xml = $self->xml($_[0]) if $_[0];
    
    my $data = {
        date   => eval { $xml->find('/transaction/date')->string_value },
        code   => eval { $xml->find('/transaction/code')->string_value },
        type   => eval { $xml->find('/transaction/type')->string_value },
        status => eval { $xml->find('/transaction/status')->string_value },
        reference       => eval { $xml->find('/transaction/reference')->string_value },
        lastEventDate   => eval { $xml->find('/transaction/lastEventDate')->string_value }, 
        grossAmount     => eval { $xml->find('/transaction/grossAmount')->string_value },
        paymentMethod => {
            type => eval { $xml->find('/transaction/paymentMethod/type')->string_value },
            code => eval { $xml->find('/transaction/paymentMethod/code')->string_value },
        },
        sender  => {
            name    => eval { $xml->find('/transaction/sender/name')->string_value },
            email   => eval { $xml->find('/transaction/sender/email')->string_value },
            phone   => {
                areaCode    =>  eval { $xml->find('/transaction/sender/phone/areaCode')->string_value },
                number      => eval { $xml->find('/transaction/sender/phone/number')->string_value },
            }
        },
        items   => []
    };

    for my $i ($xml->findnodes('//items/item')){
        my $item = {
            id          => eval { $i->find('./id')->string_value },
            description => eval { $i->find('./description')->string_value },
            quantity    => eval { $i->find('./quantity')->string_value },
            amount      => eval { $i->find('./amount')->string_value },
        };

        push @{$data->{items}}, $item;
    }

    return $data;
}

1;
__END__

=encoding utf8

=head1 NAME

PagSeguro::API::Transaction - Classe que implementa feature de transações da API

=head1 SYNOPSIS

    use PagSeguro::API;

    # new instance
    my $p = PagSeguro::API->new;
    
    #configure
    $p->email('foo@bar.com');
    $p->token('95112EE828D94278BD394E91C4388F20');

    # new transaction
    my $transaction = $p->transaction;
    my $response = $transaction->by_code('TRANSACTION_CODE');

    # or find by notification code
    $response = $transaction->by_notification_code('NOTIFICATION_CODE');

    # error
    die "Error: ". $response->error if $response->error;
    
    say $response->data;

=head1 DESCRIPTION

Esta classe implementa a parte da API responsável pelas transações.


=head1 AUTHOR

Daniel Vinciguerra <daniel.vinciguerra@bivee.com.br>


