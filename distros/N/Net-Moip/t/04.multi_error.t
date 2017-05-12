use strict;
use warnings;
use Test::More;

package HTTPTestAgent;

sub new { bless {}, shift }

sub post { shift }

sub is_success { 1 }

sub content {
    return q{<ns1:EnviarInstrucaoUnicaResponse xmlns:ns1="http://www.moip.com.br/ws/alpha/"><Resposta><ID>201410292017319240000006259167</ID><Status>Falha</Status><Erro Codigo="102">Id Próprio já foi utilizado em outra Instrução</Erro><Erro Codigo="171">TelefoneFixo do endereço deverá ser enviado obrigatorio</Erro></Resposta></ns1:EnviarInstrucaoUnicaResponse>}
}

package main;

use Net::Moip;

my $moip = Net::Moip->new(
    token => 123,
    key   => 321,
    ua    => HTTPTestAgent->new,
);

my $res = $moip->pagamento_unico({
    razao => 'Compra na loja X',
    valor => 50,
});

is_deeply(
    $res->{erros},
    [
        { codigo => 102, mensagem => 'Id Próprio já foi utilizado em outra Instrução' },
        { codigo => 171, mensagem => 'TelefoneFixo do endereço deverá ser enviado obrigatorio' },
    ],
    'parsed error response includes error message'
);


done_testing;
