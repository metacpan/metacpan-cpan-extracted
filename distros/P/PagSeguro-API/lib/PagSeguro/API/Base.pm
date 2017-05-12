package PagSeguro::API::Base;
use Moo;

use XML::LibXML;

# attributes
has email => (is => 'rw');
has token => (is => 'rw');

has environment => (is => 'rw', default => sub { 'production' });
has debug => (is => 'rw', default => sub { 0 });

sub base_uri {
    my $self = shift;
    return $self->environment eq 'production'?
        'https://pagseguro.uol.com.br' :
        'https://sandbox.pagseguro.uol.com.br';
}

sub api_uri {
    my $self = shift;
    return $self->environment eq 'production'?
        'https://ws.pagseguro.uol.com.br/v2' :
        'https://ws.sandbox.pagseguro.uol.com.br/v2';
}

sub xml {
    my $self = shift;

    my $xml = XML::LibXML->new;
    my $doc = $xml->parse_string( $_[0] ) if $_[0];

    return $doc;
}

1;

__END__

=encoding utf8

=head1 NAME

PagSeguro::API::Base - Classe base para as implementações deste módulo


=head1 DESCRIPTION

Esta classe prove interface generica com métodos e funcionalidades comuns a 
todas as classes deste modulo.


=head1 ATRIBUTOS

Esta classe disponibiliza os seguintes atributos...

=head2 email

Email do receiver.

=head2 token 

Token da API.

=head2 environment

Flag para utilização do ambiente de produção ou sandbox.


=head1 METODOS

Esta classe disponibiliza os seguintes métodos...

=head2 base_uri

URI base do PagSeguro.

=head2 api_uri

URI base da API.

=head2 xml

Parser(L<XML::LibXML>) do XML de resposta da API.


=head1 AUTHOR

Daniel Vinciguerra <daniel.vinciguerra@bivee.com.br>

