package Net::Dimona;
use strict;
use warnings;
use LWP::UserAgent;
use JSON::MaybeXS qw( encode_json decode_json );

our $VERSION = 0.01;

sub new {
    my ($class, %params) = @_;
    die 'api_key required' unless defined $params{api_key};
    return bless {
        debug   => $params{debug},
        api_key => $params{api_key} || die 'api_key is required',
        ua      => LWP::UserAgent->new(
            timeout => exists $params{timeout} ? $params{timeout} : 5,
        ),
    }, $class;
}

sub _request {
    my ($self, $method, $url, $params) = @_;

    my $res = $self->{ua}->$method(
        'https://camisadimona.com.br/api/' . $url,
        'api-key'      => $self->{api_key},
        'Accept'       => 'application/json',
        'Content-Type' => 'application/json',
        ($params ? ('Content' => encode_json($params)) : ())
    );
    return decode_json($res->decoded_content);

}

sub create_order {
    my ($self, $params) = @_;
    return $self->_request('post', 'v2/order', $params);
}

sub list_orders {
    my ($self) = @_;
    return $self->_request('get', 'v2/orders');
}

sub get_order {
    my ($self, $order_id) = @_;
    return $self->_request('get', 'v2/order/' . $order_id);
}

sub get_order_tracking {
    my ($self, $order_id) = @_;
    return $self->_request('get', 'v2/order/' . $order_id . '/tracking');
}

sub get_order_timeline {
    my ($self, $order_id) = @_;
    return $self->_request('get', 'v2/order/' . $order_id . '/timeline');
}

sub product_availability {
    my ($self, $sku) = @_;
    return $self->_request('get', 'v2/sku/' . $sku . '/availability');
}

sub quote_shipping {
    my ($self, $params) = @_;
    return $self->_request('post', 'v2/shipping', $params);
}


1;
__END__
=encoding utf8

=head1 NAME

Net::Dimona - acesso rápido à API de print-on-demand da Dimona.

=head1 SINOPSE

    use Net::Dimona;

    my $dimona = Net::Dimona->new( api_key => '...' );

    my $order = $dimona->create_order({
        order_id       => 'my_id',
        shipping_speed => 'pac',
        customer_name  => 'Jane Doe',
        items => [{
            sku => 123,
            qty => 2,
            dimona_sku_id => '010603110108',
            "designs": [
                "https://example.com/path/to/front.png",
                "https://example.com/path/to/back.png",
            ],
            "mocks": [
                "https://example.com/path/to/mock/front.png",
                "https://example.com/path/to/mock/back.png",
            ]
        }],
        address => {
            street       => 'Rua Buenos Aires',
            number       => '334',
            complement   => 'Loja',
            city         => 'Rio de Janeiro',
            state        => 'RJ',
            zipcode      => '20061000',
            neighborhood => 'Centro',
            phone        => '21 21093661',
            country      => 'BR'
        },
    });


=head2 Don't speak portuguese?

This module provides an interface to talk to the Dimona API, a print-on-demand service for t-shirts and accessories that operates in Brazil and the US and ships everywhere.

Since the target audience for this distribution is mainly brazilian, the documentation is provided in portuguese only. The API itself is already L<documented in english|https://api.camisadimona.com.br/>, as are method names and arguments.  If you need any help or want to translate it to your language, please send us some pull requests! :)


=head1 DESCRIÇÃO

Este modulo oferece uma interface para a API da Dimona, um serviço de impressão sob demanda de camisetas e outros acessórios que opera no Brasil e nos EUA e envia para todo o mundo.

=head2 new( %params )

Retorna um novo objeto C<Net::Dimona> pronto para uso. O parâmetro "api_key" é obrigatório, com a chave que você obteve criando uma conta L<no site da Dimona|https://camisadimona.com.br>.

Outros parâmetros opcionais:

=over 4

=item * C<timeout> - define quantos segundos aguardar por uma resposta da API. Padrão: 5

=back

=head2 create_order( \%params )

Cria um novo pedido na Dimona. Retorna estrutura com o id do seu pedido na Dimona, que pode ser usado em queries posteriores para referenciar este pedido.

=head2 list_orders()

Retorna lista de todos os pedidos que a sua conta já fez.

=head2 get_order( $order_id )

Recebe o id do seu pedido na Dimona (retornado por C<create_order>) e retorna o status deste pedido.

=head2 get_order_tracking( $order_id )

Recebe o id do seu pedido na Dimona (retornado por C<create_order>) e retorna informações de rastreiosobre o pedido, caso este já tenha sido enviado..

=head2 get_order_timeline( $order_id )

Recebe o id do seu pedido na Dimona (retornado por C<create_order>) e retorna o histórico de eventos associados a este id.

=head2 product_availability( $sku )

Recebe um código SKU de produto da Dimona (lista disponível no site deles) e retorna sua disponibilidade.

=head1 OBSERVAÇÕES

Até o momento nenhum parâmetro é validado no objeto, apenas do lado do servidor. Consulte a documentação oficial para mais detalhes sobre quais parâmetros e valores são aceitos.

Patches e Pull Requests são muito bem-vindos!

=head1 LICENÇA E COPYRIGHT

Copyright 2021 Breno G. de Oliveira garu at cpan.org. Todos os direitos reservados.

Este módulo é software livre; você pode redistribuí-lo e/ou modificá-lo sob os mesmos termos que o Perl. Veja a licença L<perlartistic> para mais informações.

=head1 DISCLAIMER

PORQUE ESTE SOFTWARE É LICENCIADO LIVRE DE QUALQUER CUSTO, NÃO HÁ GARANTIA ALGUMA PARA ELE EM TODA A EXTENSÃO PERMITIDA PELA LEI. ESTE SOFTWARE É OFERECIDO "COMO ESTÁ" SEM QUALQUER GARANTIA DE QUALQUER TIPO, EXPRESSA OU IMPLÍCITA. TODO O RISCO RELACIONADO À QUALIDADE, DESEMPENHO E COMPORTAMENTO DESTE SOFTWARE É DE QUEM O UTILIZAR.
