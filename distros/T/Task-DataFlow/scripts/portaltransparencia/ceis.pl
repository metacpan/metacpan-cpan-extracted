#!/usr/bin/env perl

use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/../../lib";

package CeisPages;

use Moose;
extends 'DataFlow::Proc::MultiPageURLGenerator';

use LWP::UserAgent;
use HTML::TreeBuilder::XPath;
use URI;

has '+produce_last_page' => (
    default => sub {
        return sub {
            my $url = shift;

            my $get  = LWP::UserAgent->new;
            my $html = $get->get($url)->decoded_content;

            my $texto =
              HTML::TreeBuilder::XPath->new_from_content($html)
              ->findvalue('//p[@class="paginaAtual"]');
            die q{Não conseguiu determinar a última página}
              unless $texto;
            return $1 if $texto =~ /\d\/(\d+)/;
          }
    },
);
has '+make_page_url' => (
    default => sub {
        return sub {
            my ( $self, $url, $page ) = @_;

            my $u = URI->new($url);
            $u->query_form( $u->query_form, Pagina => $page );
            return $u->as_string;
          }
    },
);

package main;

use DataFlow;

use Encode;

my $flow = dataflow(
    CeisPages->new( first_page => -5, deref => 1 ),
    'URLRetriever',
    [
        HTMLFilter => {
            search_xpath =>
              '//div[@id="listagemEmpresasSancionadas"]/table/tbody/tr',
        }
    ],
    [
        HTMLFilter => {
            search_xpath => '//td',
            result_type  => 'VALUE',
            ref_result   => 1,
        }
    ],
    sub {    # remove leading and trailing spaces
        s/^\s*//;
        s/\s*$//;
        s/[\r\n\t]+/ /g;
        s/\s\s+/ /g;
        return $_;
    },
    sub {
        my $internal = decode( "iso-8859-1", $_ );
        return encode( "utf8", $internal );
    },
    [ NOP => { name => 'espiando', dump_output => 1, } ],
    [
        CSV => {
            name           => 'csv',
            direction      => 'CONVERT_TO',
            converter_opts => { binary => 1, },
            headers        => [
                'CNPJ/CPF',   'Nome/Razão Social/Nome Fantasia',
                'Tipo',       'Data Inicial',
                'Data Final', 'Nome do Órgão/Entidade',
                'UF',         'Fonte',
                'Data'
            ],
            dump_output => 1,
        }
    ],
    [ SimpleFileOutput => { file => '> /tmp/ceis.csv', ors => "\n" } ]
);

##############################################################################

my $base = q{http://www.portaltransparencia.gov.br} . '/'
  . q{ceis/EmpresasSancionadas.asp?paramEmpresa=0};

$flow->input($base);

my @res = $flow->flush;

#use Data::Dumper;
#print Dumper(\@res);
