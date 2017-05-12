package POD2::PT_BR;
use warnings;
use strict;

use utf8;
use base 'POD2::Base';

our $VERSION = '0.06';

sub search_perlfunc_re {
    return 'Listagem Alfabética das Funções do Perl';
}

sub pod_info {
    perlbook     => '5.10.1',
    perlboot     => '5.10.1',
    perldsc      => '5.8.7',
    perlintro    => '5.10.1',
    perlreftut   => '5.10.1',
    perlstyle    => '5.10.1',
    perlutil     => '5.8.7',
}

42;
__END__
=encoding utf8

=head1 NAME

POD2::PT_BR - Brazilian portuguese translation of Perl core documentation

=head1 NOME

POD2::PT_BR - Tradução da documentação do Perl para português brasileiro

=head1 SINOPSE

Na linha de comando

  > perldoc POD2::PT_BR::<podpage>

ou, a maneira mais amigável de chamar a versão em português:

  > perldoc -L PT_BR <podpage>
  > perldoc -L PT_BR -f <função>
  > perldoc -L PT_BR -q <FAQregex>

Se a documentação (POD) ainda não estiver disponível em português, ele exibe a versão original. Assim, podemos simplesmente criar um "alias" e evitar ter que digitar o "-L PT_BR" sempre que quisermos ver a documentação:

  > alias perldoc='perldoc -L PT_BR'

E assim veremos a documentação em português sempre que disponível!

  > perldoc <podpage> 

Esse módulo foi feito para ser usado associado ao comando C<perldoc>, como mostrado acima. Por favor consulte a documentação do L<< POD2::Base >> para uso como um módulo.

=head1 DESCRIÇÃO

Esse é o resultado do projeto de tradução para o português brasileiro da documentação oficial do Perl. Foi - e ainda é - um enorme trabalho! :-)

Veja L<< http://perldoc.perl.org.br >> para mais detalhes sobre o projeto, e como ajudar você também.

Uma vez instalado, a documentação traduzida pode ser acessada como mencionado na sinopse deste documento.

=head1 Como funciona o projeto

O projeto de tradução da documentação Perl para o português é uma iniciativa 
relativamente nova, que até então vem se baseando no louvável trabalho 
colaborativo da comunidade Perl na wiki disponível em 
L<< http://perldoc.perl.org.br >>

=head1 Como colaborar

Basta criar seu usuário em nossa wiki e editar os documentos. Não esqueça de 
adicionar seu nome na lista de tradutores!


=head1 AUTHORS / AUTORES

The Brazilian Perl Community / Comunidade Brasileira de Perl

Translators (in alphabetical order):
Tradutores (em ordem alfabética):

=over 4

=item * Breno G. de Oliveira

=item * Daniel Mantovani

=item * Eden Cardim

=item * Frederico Recksy

=item * Igor Sutton

=item * Joênio Costa Marques

=item * Marco Lima

=item * Nicholas Amorim

=item * Nelson Ferraz

=item * Roan Brasil Monteiro

=item * Ronaldo Lima


=back

Caso você tenha contribuído para alguma das traduções disponíveis neste módulo e não foi citado, por favor entre em contato com o mantenedor para que isso seja corrigido o quanto antes.


=head1 BUGS

Please report any bugs or feature requests to C<bug-pod2-pt_br at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=POD2-PT_BR>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc POD2::PT_BR


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=POD2-PT_BR>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/POD2-PT_BR>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/POD2-PT_BR>

=item * Search CPAN

L<http://search.cpan.org/dist/POD2-PT_BR/>

=back


=head1 ACKNOWLEDGEMENTS

Many thanks are in order to Adriano Ferreira for his L<< POD2::Base >> module, 
and to the nice people involved in the translation effort worldwide.

=head1 SEE ALSO

L<< POD2::Base >>

L<< POD2::IT >>, L<< POD2::FR >>, L<< POD2::LT >>

L<< http://pod2.perl.org >>

L<< http://perldoc.perl.org.br >>


=head1 COPYRIGHT & LICENSE

Copyright 2009-2010 The Brazilian Perl Community.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
