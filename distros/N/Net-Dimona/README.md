# Net::Dimona

Acesso rápido à API de print-on-demand da Dimona.

## Sinopse

```perl
    use Net::Dimona;

    my $dimona = Net::Dimona->new( api_key => '...' );

    my $order = $dimona->create_order({ ... });

    say 'Pedido registrado como ' . $order->{order};
```

## Descrição

Este modulo oferece uma interface para a API da Dimona, um serviço de impressão sob demanda de camisetas e outros acessórios que opera no Brasil e nos EUA e envia para todo o mundo.

## Instalação

    > cpanm Net::Dimona

Se preferir instalar manualmente, baixe/clone esse repositório ou baixe/descompacte o .tar.gz do CPANe execute:

    > perl Makefile.PL
    > make
    > make test && make install

## Copyright

Copyright (C) 2021 Breno G. de Oliveira
