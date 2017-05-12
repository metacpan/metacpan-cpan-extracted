use strict;
use warnings;
use Test::More tests => 11;
use Test::Fatal;

use Net::TinyERP;

{
    no warnings 'redefine';
    *Net::TinyERP::NotaFiscal::_post = sub {
        my ($self, $url, $params) = @_;
        like $url, qr{https://api.tiny.com.br/api2/.+\.php}, 'route match';
        is ref($params), 'HASH', 'params look like a hashref';
        return 1;
    };
}

my $tiny = Net::TinyERP->new( token => 'abc123' );

ok my $nf = $tiny->nota_fiscal
    => 'able to invoke "nota_fiscal"';

isa_ok $nf, 'Net::TinyERP::NotaFiscal';

can_ok $nf, qw( pesquisar obter obter_xml obter_link incluir emitir );

is ${$nf->{parent_token}}, 'abc123' => 'parent token match';
$tiny->{token} = 'def456';
is ${$nf->{parent_token}}, 'def456' => 'parent token updated';

subtest 'pesquisar()' => sub {
    plan tests => 6;

    like(
        exception { $nf->pesquisar },
        qr/precisa de HASHREF/,
        'pesquisar() needs args',
    );
    like(
        exception { $nf->pesquisar(123) },
        qr/precisa de HASHREF/,
        'pesquisar() needs arg as ref',
    );
    like(
        exception { $nf->pesquisar( [123] ) },
        qr/precisa de HASHREF/,
        'pesquisar() needs HASHREF arg',
    );
    ok $nf->pesquisar({ nome=> 'Beatriz' }), 'pesquisar() with HASHREF works';
};

subtest 'obter()' => sub {
    plan tests => 5;

    like(
        exception { $nf->obter },
        qr/argumento "id"/,
        'obter() requires "id" argument',
    );
    like(
        exception { $nf->obter('abc') },
        qr/argumento "id"/,
        'obter() needs numeric "id"',
    );
    ok $nf->obter(123), 'obter() with numeric id works';
};

subtest 'obter_xml()' => sub {
    plan tests => 1;
    like(
        exception { $nf->obter_xml('123') },
        qr/nao foi implementado/,
        'obter_xml() not implemented',
    );
};

subtest 'obter_link()' => sub {
    plan tests => 5;

    like(
        exception { $nf->obter_link },
        qr/argumento "id"/,
        'obter_link() requires "id" argument',
    );
    like(
        exception { $nf->obter_link('abc') },
        qr/argumento "id"/,
        'obter_link() needs numeric "id"',
    );
    ok $nf->obter_link(123), 'obter_link() with numeric id works';
};

subtest 'incluir()' => sub {
    plan tests => 6;

    like(
        exception { $nf->incluir },
        qr/precisa de HASHREF/,
        'incluir() needs args',
    );
    like(
        exception { $nf->incluir(123) },
        qr/precisa de HASHREF/,
        'incluir() needs arg as ref',
    );
    like(
        exception { $nf->incluir( [123] ) },
        qr/precisa de HASHREF/,
        'incluir() needs HASHREF arg',
    );
    ok $nf->incluir({ natureza_operacao => 'venda' }), 'incluir() with HASHREF works';
};


subtest 'emitir()' => sub {
    plan tests => 5;

    like(
        exception { $nf->emitir },
        qr/argumento "id"/,
        'emitir() requires "id" argument',
    );
    like(
        exception { $nf->emitir('abc') },
        qr/argumento "id"/,
        'emitir() needs numeric "id"',
    );
    ok $nf->emitir(123), 'emitir() with numeric id works';
};


