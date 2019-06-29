Net-TinyERP
===========

Este módulo interage com a API (2.0) do [TinyERP](http://tiny.com.br).

#### Don't speak portuguese?

*This module provides an interface to talk to Tiny ERP's REST API.
Tiny ERP is a brazilian Enterprise Resource Planning company with
several solutions for CRM, contracts, products, tax invoices, etc,
focused on brazilian small and medium-sized businesses.
Since the target audience for this distribution is mainly brazilian
developers, the documentation is provided in portuguese only.
If you need any help or want to translate it to your language, please
send us some pull requests! :)*


No momento, apenas a API de notas fiscais (NF-e e NFS-e) foi implementada. Se quiser
acessar [outra parte da API](https://tiny.com.br/info/api-desenvolvedores)
como produtos, vendedores e crm, envie-nos um Pull Request :)

```perl
    my $api = Net::TinyERP->new(
        token       => 'abc123', # <-- OBRIGATÓRIO
    );

    my $res = $api->nota_fiscal->incluir({
        natureza_operacao => 'Venda de Mercadorias',
        ...,
        cliente       => { ... },
        itens         => [ { item => { ... } }, ... ],
        parcelas      => [ { parcela => { ... } }, ... ],
        transportador => { ... },
    });
```

#### ANTES DE USAR, VOCÊ VAI PRECISAR DE:

* Uma conta na TinyERP com acesso à API

Acesse http://www.tiny.com.br e crie sua conta em um plano que
tenha suporte à API.

* Um token de acesso à API

Veja [Como gerar seu token](https://tiny.com.br/info/api.php?p=api2-gerar-token-api).

* Um certificado digital A1

Adicione seu certificado dentro da interface web do Tiny antes de usar este módulo.

* Suporte a HTTPS

Todas as chamadas à API são feitas via HTTPS então certifique-se de que as
libs de SSL estão instaladas e que a rede permite esse tipo de acesso.

### API

No momento apenas a API de manipulação de Notas Fiscais está disponível, NF-e e NFS-e.

Para mais informações, [consulte a documentação completa](https://metacpan.org/pod/Net::TinyERP).



