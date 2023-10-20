use strict;
use warnings;
use Scalar::Util ();
use utf8;

package Net::Correios::SRO;

sub new {
    my ($class, $parent) = @_;
    Scalar::Util::weaken($parent);
    return bless { parent => $parent }, $class;
}

# minha versão da consulta por SRO ;)
sub busca {
    my ($self, $tipo, @sro) = @_;

    if (length($tipo) > 1) {
        unshift @sro, $tipo;
        $tipo = 'T';
    }

    my $res = $self->objetos( objetos => \@sro, resultado => $tipo );
    my %data;
    foreach my $item (@{$res->{objetos}}) {
        $data{ $item->{codObjeto} } = $item;
        $data{ $item->{codObjeto} }{situacao} = $tipo eq 'P'
            ? 'indisponível'
            : ($item->{mensagem} && $item->{mensagem} =~ /\ASRO-020/) ? 'não encontrado'
            : $self->nome_do_evento($item->{eventos}[0]{codigo}, $item->{eventos}[0]{tipo});
    }
    return \%data;
}

sub nome_do_evento {
    my ($self, $codigo, $tipo) = @_;
    return 'indisponivel' unless defined $codigo && defined $tipo;
    if ($codigo eq 'BDR' || $codigo eq 'BDE' || $codigo eq 'BDI') {
        # estado final. entrega efetuada!
        return 'entregue' if $tipo <= 1;

        # acionar correios (produto extraviado, etc).
        return 'erro' if    $tipo == 9  || $tipo == 12 || $tipo == 28
                         || $tipo == 37 || $tipo == 43 || $tipo == 50
                         || $tipo == 51 || $tipo == 52 || $tipo == 80
        ;

        # pacote aguardando retirada pelo interessado.
        return 'retirar' if $tipo == 54 || $tipo == 2;

        # entrega incompleta, pacote retornando.
        return 'incompleto'
            if (  ($tipo != 20 && $tipo != 7 && $tipo <= 21)
                || $tipo == 26 || $tipo == 33 || $tipo == 36
                || $tipo == 40 || $tipo == 42 || $tipo == 48
                || $tipo == 49 || $tipo == 56
            );

        return 'devolvido' if $tipo == 23;

        return 'acompanhar';
    }
    elsif ($codigo eq 'FC' && $tipo == 1) {
        return 'incompleto';
    }
    elsif ($codigo eq 'OEC' && $tipo == 9) {
        return 'incompleto';
    }
    elsif (
        # pacote aguardando retirada.
           ($codigo eq 'LDI' && ($tipo <= 3 || $tipo == 14))
        || ($codigo eq 'OEC' && $tipo == 0)
    ) {
        return 'retirar';
    }
    else {
        return 'acompanhar';
    }
}

# http://www.correios.com.br/para-sua-empresa/servicos-para-o-seu-contrato/guias/enderecamento/arquivos/guia_tecnico_encomendas.pdf/at_download/file
sub sro_ok {
    if ( $_[-1] =~ m/^[A-Z|a-z]{2}([0-9]{8})([0-9])BR$/i ) {
        my ( $numeros, $dv ) = ($1, $2);
        my @numeros = split // => $numeros;
        my @magica  = ( 8, 6, 4, 2, 3, 5, 9, 7 );

        my $soma = 0;
        foreach ( 0 .. 7 ) {
            $soma += ( $numeros[$_] * $magica[$_] );
        }

        my $resto = $soma % 11;
        my $dv_check = $resto == 0 ? 5
                     : $resto == 1 ? 0
                     : 11 - $resto
                     ;
        return $dv == $dv_check;
    }
    return;
}

sub objetos {
    my ($self, %args) = @_;

    my @codes;
    foreach my $code (@{$args{objetos}}) {
        die "código SRO '$code' é inválido" unless defined $code && length($code) == 13;
        push @codes, uc($code);
    }
    die "pelo menos 1 objeto é necessário para consulta" unless @codes;
    my $tipo = $args{resultado} || 'U';
    die "resultado precisa ser 'U' (último), 'P' (primeiro) ou 'T' (todos)"
        unless $tipo eq 'T' || $tipo eq 'U' || $tipo eq 'P';

    my $query_string = 'codigosObjetos=' . join('&codigosObjetos=', @codes)
                     . '&resultado=' . $tipo;

    my $url = 'srorastro/v1/objetos?' . $query_string;
    my $parent = $self->{parent};

    my $res = $parent->make_request('cartao', 'GET', $url);

    return $parent->parse_response($res);
}

sub imagens {
    my ($self, @codes) = @_;
    my $parent = $self->{parent};

    my $body = '[' . join(',', map qq("$_"), @codes) . ']';

    my $res = $parent->make_request(
        'cartao',
        'POST',
        'srorastro/v1/objetos/imagens',
        { content => '[' . join(',', map qq("$_"), @codes) . ']' }
    );
    return $parent->parse_response($res);
}

sub recibo {
    my ($self, $recibo) = @_;
    my $parent = $self->{parent};

    my $res = $parent->make_request('cartao', 'GET', 'srorastro/v1/recibo/' . $recibo);
    return $parent->parse_response($res);
}

1;
__END__

=head1 NAME

Net::Correios::SRO - consulte o rastreio de pacotes dos Correios

=head1 SINOPSYS

    my $correios = Net::Correios->new( %credenciais );

    my $rastreio = $correios->sro->busca( 'TF884516597BR', 'YJ460348417BR' );



=head1 DESCRIÇÃO

Este módulo oferece uma interface para consulta ao Serviço de Rastreamento
de Objetos (SRO) dos Correios.

=head1 MÉTODOS

=head2 busca( @codigos )

=head2 busca( $tipo, @codigos )

    # busca pelo rastreio de 1 código:
    $sro = $correios->sro->busca( 'YJ460348417BR' );

    # busca pelo rastreio de N códigos:
    $sro = $correios->sro->busca( 'YJ460348417BR', 'QP302718234BR' );

    # o primeiro parâmetro pode explicitar o tipo (padrão é 'T'):
    $sro = $correios->sro->busca( 'U', 'QP302718234BR' );

    say $sro->{'QP302718234BR'}{'peso'};
    say $sro->{'QP302718234BR'}{'eventos'}[0]{descricao};

O método C<busca()> é uma versão incrementada do método C<objetos()> abaixo
e foi criado como seu substituto.

Ele recebe um ou mais códigos de rastreio de objetos dos Correios e retorna
um hashref em que cada chave é um desses códigos. Por padrão a lista de
eventos de rastreio inclui todos os eventos, mas você pode passar o tipo
explicitamente como primeiro parâmetro ('P' para primeiro evento, 'U' para
último, ou 'T' para todos).

O conteúdo (valor) de cada chave é um hashref com as mesmas informações
obtidas pela consulta a C<objetos()>. Se o tipo de evento for 'T' (padrão)
ou 'U', a estrutura será acrescida do campo C<situacao> que pode conter
os seguintes valores:

=over 4

=item 'entregue' - entrega concluida, nada mais a ser feito.

=item 'erro' - acionar Correios (objetos perdidos, extraviado, etc).

=item 'retirar' - pacote na agência, aguardando retirada pelo interessado.

=item 'incompleto' - pacote retornado ao remetente.

=item 'acompanhar' - pacote em trânsito.

=back

=head2 objetos( objetos => \@codigos, resultado => $tipo )

    my $sro = $correios->sro->objetos(
        objetos   => ['QP302718234BR', 'YJ460348417BR'],
        resultado => 'U',
    );

    foreach my $obj ($sro->{objetos}->@*) {
        say $obj->{codObjeto};
        say $obj->{peso};
        say $obj->{eventos}[0]{descricao};
    }

Interface direta para a chamada ao endpoint "objetos" da API dos Correios.
Recebe uma lista de objetos e um tipo de resultado para os eventos ('U' para
só retornar o último evento registrado, 'T' para todos os eventos e 'P' para
retornar apenas o primeiro evento registrado). Retorna uma estrutura que lista
os objetos dentro da chave 'objetos', em nenhuma ordem garantida.

Para simplificar a consulta e acesso aos dados de rastreio, recomendamos o
uso do método C<buscar> em vez deste.

=head2 sro_ok( $codigo )

    say "código inválido!"
        unless $correios->sro->sro_ok( 'QP302718234BR' );

Retorna verdadeiro se o código de rastreamento passado é válido, caso
contrário retorna falso. Ela deve ser usada quando você quer apenas saber
se o código é válido ou não, sem precisar fazer uma consulta HTTP ao site
dos Correios.

Note que essa função B<não> elimina espaços da string, você deve fazer
sua própria higienização antes de testar valores, ou ela pode retornar
falso-negativos.

=head2 nome_do_evento( $codigo_do_evento, $tipo_do_evento )

Recebe o código e o tipo de um evento retornado pelos Correios e traduz
para um nome de fácil compreensão ('acompanhar', 'entregue', 'erro',
'retirar' ou 'incompleto'). Esse método é usado internamente pelo método
C<busca()> para traduzir a situação do último evento de um rastreio.
(veja a documentação do C<busca()> para mais detalhes).

=head1 VEJA TAMBÉM

L<< Net::Correios >>
