package PagSeguro::API;
# ABSTRACT: PagSeguro::API - UOL PagSeguro Payment Gateway API Module
our $VERSION = '0.009.1';

use Moo;

use PagSeguro::API::Payment;
use PagSeguro::API::Transaction;
use PagSeguro::API::Notification;

# attributes
has email => (is => 'rw');
has token => (is => 'rw');

has environment => (is => 'rw', default => sub { 'production' });
has debug => (is => 'rw', default => sub { 0 });

# methods
sub payment_request {
    my $self = shift;

    return PagSeguro::API::Payment
        ->new( %{$self->_config} );
}

sub notification {
    my $self = shift;

    return PagSeguro::API::Notification
        ->new( %{$self->_config} );
}

sub transaction {
    my $self = shift;

    return PagSeguro::API::Transaction
        ->new( %{$self->_config} );
}

sub _config {
    my $self = shift;
    return {
        email => $self->email,
        token => $self->token,

        debug => $self->debug,
        environment => $self->environment,
    };
}


1;
__END__

=encoding utf8

=head1 NAME

PagSeguro::API - API for PagSeguro payment gateway


=head1 SYNOPSIS

    my $p = PagSeguro::API->new;
    
    # configure
    $p->email('foo@bar.com');
    $p->token('95112EE828D94278BD394E91C4388F20');

    # new payment request object
    my $payment = $p->payment_request;
    $payment->reference('XXX');
    $payment->notification_url('http://google.com');
    $payment->redirect_url('http://url_of_love.com.br');

    # adding new item
    $payment->add_item(
        id          => $product->id,
        description => $product->title,
        amount      => $product->price,
        weight      => $product->weight
    );

    my $response = $payment->request;

    # error
    die "Error: ". $response->error if $response->error;

    my $data = $response->data;
    say $data->{payment_url}; 


=head1 DESCRIPTION

B<PagSeguro> Gateway Payment API implementation.

PagSeguro is a Brazilian very common payment gateway and for this case, the 
documentation that will provided here will be write in Portuguese.

If you don't speak Portuguese and need to use this module please contact author 
for some help or ask something.


I<< Now In Portuguese >>

Este módulo foi criado para prover uma implementação à API do PagSeguro em Perl 
de forma simples e pratica.


=head2 Status

This is a very new module and may contain some bugs. Please do not use in 
production.

Este módulo é muito novo e pode conter alguns bugs. Por favor não use em 
produção.


=head2 Requisitos

Este módulo requer os seguintes módulos não core para funcionar corretamente...

=over

=item Moo

=item XML::LibXML

=back

=head2 Configuração

    my $p = PagSeguro::API->new;

    $p->email('joe.doe@sualoja.com.br');
    $p->token('seu token');

    # environment: default é 'production'
    $p->environment('sandbox');

Para utilizar a API do PagSeguro você precisa ter um C<< e-mail >> e um 
C<< token >> cadastrados.

A flag c<< environment >> serve para configurar seu ambiente para rodar em 
sandbox (ambiente de testes do PagSeguro) ou em produção.

=head1 METODOS

Esta classe disponibiliza os seguintes métodos...

=head2 new 

    my $p = PagSeguro::API->new;

    my $p = PagSeguro::API->new(
        email => 'joe.doe@sualoja.com.br',
        token => 'seu token'
    );

Este é o construtor da classe e pode receber como parâmetro, diretamente, as
credenciais de autenticação para utilizar a API como C<email>, C<token> e
C<environment>.

=head2 payment_request

    my $payment = $p->payment_request;

Este método retorna um objeto da classe C<PagSeguro::API::Payment>.    

=head2 notification

    my $payment = $p->notification;

Este método retorna um objeto da classe C<PagSeguro::API::Notification>.    


=head2 transaction

    my $payment = $p->transaction;

Este método retorna um objeto da classe C<PagSeguro::API::Transaction>.    


=head1 TODO

Algumas funcionalidades que estão por vir.

    * Utilizar um módulo mais performático para substituir o LWP::UserAgent
    * Melhorias na documentação e criação de Cookbook
    * Concluir a implementação de toda a API de consulta de transações
    * Melhoria nos testes


=head1 AUTHOR

Daniel Vinciguerra <daniel.vinciguerra at bivee.com.br>

