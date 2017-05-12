use strict;
use warnings;
use Test::More;

package HTTPTestAgent;

sub new { bless {}, shift }

sub post {
    my ($self, $url, $auth, $content) = @_;

    Test::More::is(
        $url,
        'https://api.moip.com.br/ws/alpha/EnviarInstrucao/Unica',
        'requesting the proper url'
    );

    Test::More::is_deeply(
        $auth,
        [ 'Authorization' => 'Basic QUJDOkRFRg==' ],
        'request with the proper auth header'
    );

    Test::More::ok index($content, '<Valores><Valor>10.3</Valor></Valores>') > 0,
   'found Valor tag';

    Test::More::ok index($content, "<InstrucaoUnica TipoValidacao='Transparente'>") > 0,
    'found TipoValidacao attribute';

    Test::More::ok index($content, '<CEP>22222-222</CEP>') > 0,
    'found CEP data with proper case';

    Test::More::ok index($content, '<URLNotificacao>http://example.com</URLNotificacao>') > 0,
    'found URLNotificacao with proper case';

    Test::More::ok index($content, '<URLRetorno>http://example.com/return</URLRetorno>') > 0,
    'found URLRetorno with proper case';

    return $self;
}

sub is_success { 1 }

sub content {
    return q{<ns1:EnviarInstrucaoUnicaResponse xmlns:ns1="http://api.moip.com.br/ws/alpha/"><Resposta><ID>201410290037405090000006256931</ID><Status>Sucesso</Status><Token>I2T011T4Q1L0V23910N0W3I71410U5P0E9I02010C0G0U0K6Z285U6Q9D3L1</Token></Resposta></ns1:EnviarInstrucaoUnicaResponse>};
}

package main;

use Net::Moip;
pass 'Net::Moip loaded successfully';

ok my $moip = Net::Moip->new(
    token => 'ABC',
    key   => 'DEF',
), 'new Net::Moip object';

isa_ok $moip, 'Net::Moip';

can_ok $moip, qw( sandbox api_url );

is(
    $moip->api_url,
    'https://api.moip.com.br/ws/alpha/EnviarInstrucao/Unica',
    'default Net::Moip object points to production'
);

is $moip->sandbox, 0, 'default is no sandbox';

$moip->sandbox(1);

is $moip->sandbox, 1, 'switched to sandbox';

is(
    $moip->api_url,
    'https://desenvolvedor.moip.com.br/sandbox/ws/alpha/EnviarInstrucao/Unica',
    'sandbox API endpoint switched properly'
);

ok $moip = Net::Moip->new(
    token => 'ABC',
    key   => 'DEF',
    ua    => HTTPTestAgent->new,
), 'new Net::Moip object with user agent';


my $res = $moip->pagamento_unico({
    razao          => 'Compra de produto',
    tipo_validacao => 'Transparente',
    valor          => 10.30,
    id_proprio     => 'lala',
    url_notificacao => 'http://example.com',
    url_retorno     => 'http://example.com/return',
    pagador => {
        endereco_cobranca => {
            cep => '22222-222',
        },
    },
});

is $res->{id}, '201410290037405090000006256931', 'parsed response includes id';
is $res->{status}, 'Sucesso', 'parsed repsonse includes status';
is(
    $res->{token},
    'I2T011T4Q1L0V23910N0W3I71410U5P0E9I02010C0G0U0K6Z285U6Q9D3L1',
    'parsed response includes token'
);

is ref $res->{response}, 'HTTPTestAgent', 'parsed response includes object';

ok !exists $res->{erros}, 'no errors while parsing';


done_testing;
