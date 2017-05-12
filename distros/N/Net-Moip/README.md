Net-Moip
========

Interface com o gateway de pagamentos Moip.

```perl
    use Net::Moip;

    my $gateway = Net::Moip->new(
        token => 'MY_MOIP_TOKEN',
        key   => 'MY_MOIP_KEY',
    );

    my $res = $gateway->pagamento_unico({
        razao          => 'Pagamento para a Loja X',
        tipo_validacao => 'Transparente',
        valor          => 59.90,
        id_proprio     => 1,
        pagador => {
            id_pagador => 1,
            nome       => 'Cebolácio Júnior Menezes da Silva',
            email      => 'cebolinha@exemplo.com',
            endereco_cobranca => {
                logradouro    => 'Rua do Campinho',
                numero        => 9,
                bairro        => 'Limoeiro',
                cidade        => 'São Paulo',
                estado        => 'SP',
                pais          => 'BRA',
                cep           => '11111-111',
                telefone_fixo => '(11)93333-3333',
            },
        },
    });

    if ($res->{status} eq 'Sucesso') {
        print $res->{token};
        print $res->{id};
    }
```

### Instalação ###

Usando o cpan:

    cpan Net::Moip

Usando o cpanm:

    cpanm Net::Moip

Instalação manual:

    perl Makefile.PL
    make
    make test
    make install

