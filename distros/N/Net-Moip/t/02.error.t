use strict;
use warnings;
use Test::More;

package HTTPTestAgent;

sub new { bless {}, shift }

sub post { shift }

sub is_success { 1 }

sub content {
    return q{<ns1:EnviarInstrucaoUnicaResponse xmlns:ns1="http://www.moip.com.br/ws/alpha/"><Resposta><ID>201410290130249120000006256992</ID><Status>Falha</Status><Erro Codigo="176">CEP do endereÃ§o deverÃ¡ ser enviado obrigatoriamente</Erro></Resposta></ns1:EnviarInstrucaoUnicaResponse>"};
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

is(
    $res->{id},
    '201410290130249120000006256992',
    'parsed error response has token'
);

is $res->{status}, 'Falha', 'parsed error response has status';

is ref $res->{erros}, 'ARRAY', 'parsed error response has errors array';

is_deeply(
    $res->{erros}[0],
    { codigo => 176, mensagem => 'CEP do endereÃ§o deverÃ¡ ser enviado obrigatoriamente' },
    'parsed error response includes error message'
);

done_testing;
