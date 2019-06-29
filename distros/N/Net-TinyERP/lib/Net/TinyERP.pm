package Net::TinyERP;
use strict;
use warnings;
use Net::TinyERP::NotaFiscal;
use Net::TinyERP::NotaFiscalServicos;

our $VERSION = '0.07';

sub new {
    my ($class, @params) = @_;
    die 'Net::TinyERP->new() precisa do argumento "token"' unless @params;
    my %params = @params > 1 ? @params : %{$params[0]};
    my $self = {
        token       => $params{token} || die 'argumento "token" obrigatório',
        api_version => $params{api_version} || '2.0',
    };
    bless $self, $class;
}

sub nota_fiscal {
    my ($self) = @_;
    if (!exists $self->{_nf_obj}) {
        $self->{_nf_obj} = Net::TinyERP::NotaFiscal->new($self);
    }
    return $self->{_nf_obj};
}

sub nota_servicos {
    my ($self) = @_;
    if (!exists $self->{_nfs_obj}) {
        $self->{_nfs_obj} = Net::TinyERP::NotaFiscalServicos->new($self);
    }
    return $self->{_nfs_obj};
}

1;
__END__
=encoding utf8

=head1 NAME

Net::TinyERP - interface com a API REST do Tiny ERP

=head1 SINOPSE

    my $api = Net::TinyERP->new(
        token       => 'abc123', # <-- OBRIGATÓRIO
        api_version => '2.0',    # <-- Opcional
    );

    my $res = $api->nota_fiscal->incluir({
        natureza_operacao => 'Venda de Mercadorias',
        ...,
        cliente       => { ... },
        itens         => [ { item => { ... } }, ... ],
        parcelas      => [ { parcela => { ... } }, ... ],
        transportador => { ... },
    });

    my @ids;
    if ($res->{status} eq 'OK') {
        foreach my $registro (@{ $res->{registros} }) {
            if ($registro->{registro}{status} eq 'OK') {
                push @ids, $registro->{registro}{id};
            }
        }
    }

    foreach my $id (@ids) {
        my $nota = $api->nota_fiscal->obter( $id );
        say $nota->{descricao_situacao};
    }


=head2 Don't speak portuguese?

This module provides an interface to talk to Tiny ERP's REST API.
Tiny ERP is a brazilian Enterprise Resource Planning company with
several solutions for CRM, contracts, products, tax invoices, etc,
focused on brazilian small and medium-sized businesses.
Since the target audience for this distribution is mainly brazilian
developers, the documentation is provided in portuguese only.
If you need any help or want to translate it to your language, please
send us some pull requests! :)

=head1 DESCRIÇÃO

Este módulo interage com a API (2.0) do L<TinyERP|http://tiny.com.br>.

No momento, apenas a API de notas fiscais foi implementada. Se quiser
acessar L<outra parte da API|https://tiny.com.br/info/api-desenvolvedores>
como produtos, vendedores e crm, envie-nos um Pull Request :)

=head1 ANTES DE USAR, VOCÊ VAI PRECISAR DE:

=head2 Uma conta na TinyERP com acesso à API

Acesse L<http://www.tiny.com.br> e crie sua conta em um plano que
tenha suporte à API.

=head2 Um token de acesso à API

Veja L<Como gerar seu token|https://tiny.com.br/info/api.php?p=api2-gerar-token-api>.

=head2 Um certificado digital A1

Adicione seu certificado dentro da interface web do Tiny antes de usar este módulo.

=head2 Suporte a HTTPS

Todas as chamadas à API são feitas via HTTPS.

=head1 API

No momento apenas a API de manipulação de Notas Fiscais está disponível.

=head2 nota_fiscal()

Retorna o objeto para manipulação de Notas Fiscais Eletrônicas (NFe).
Para mais informações, consulte a documentação da classe
L<Net::TinyERP::NotaFiscal>.

=head2 nota_servicos()

Retorna o objeto para manipulação de Notas Fiscais de Serviço Eletrônicas
(NFSe). Para mais informações, consulte a documentação da classe
L<Net::TinyERP::NotaFiscalServicos>.

=head1 COPYRIGHT e LICENÇA

Copyright (c) 2016-2019 - Breno G. de Oliveira C<< garu at cpan.org >>.
Todos os direitos reservados.

Este módulo é software livre; você pode redistribuí-lo e/ou modificá-lo sob os mesmos
termos que o Perl. Veja a licença L<perlartistic> para mais informações.

=head1 DISCLAIMER

PORQUE ESTE SOFTWARE É LICENCIADO LIVRE DE QUALQUER CUSTO, NÃO HÁ GARANTIA ALGUMA
PARA ELE EM TODA A EXTENSÃO PERMITIDA PELA LEI. ESTE SOFTWARE É OFERECIDO "COMO ESTÁ"
SEM QUALQUER GARANTIA DE QUALQUER TIPO, EXPRESSA OU IMPLÍCITA. TODO O RISCO RELACIONADO
À QUALIDADE, DESEMPENHO E COMPORTAMENTO DESTE SOFTWARE É DE QUEM O UTILIZAR.
