# $Id: Utils.pm,v 1.2 2003/05/17 14:30:40 devel Exp $

package NTS::Utils;

#use 5.008;
use strict;
use warnings FATAL => 'all';

our $VERSION = '2.0';

# Recupega Post com multiples values
sub getForm {
    my($i,@j,$k,%r,$c,%concat);
   
    my $r = Apache->request;
    $c = shift;
    $i = $c;

    return () unless defined $i;
    while ($i =~ s/^\&?([a-zA-Z0-9-_\%\.\,\+]+)=([a-zA-Z0-9-_\*\@\%\.\,\+\/]+)?&?//sx) {
       $j[0] = $1;
       $j[1] = $2;

       # Trasnforma os chars especiais em normais
       $j[0] =~ tr/+/ /;
       $j[0] =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
       
       if (defined $j[1]) {
           $j[1] =~ tr/+/ /;
           $j[1] =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
       }

       # Verifica quantas vezes se repete     
       $k = $c =~ s/(^|&)($j[0]=)/$1$2/gi;

       # Verifica se joga em array ou hash
       if ($k > 1) { push (@{$r{$j[0]}},$j[1]); }
       else { $r{$j[0]} = $j[1] }

       # Verifica se deve fazer concat
       $concat{$1}->{$2} = $j[1] if ($j[0] =~ /^concat\.(.*)\.([0-9]+)$/);

       $k = 0;
    }

    # Retorna dados do concat corretos
    foreach $i (keys %concat) {
        undef $r{$i};
        foreach (sort keys %{$concat{$i}}) {
            $r{$i} .= $concat{$i}->{$_} if $concat{$i}->{$_};
        }
    }

    return %r if %r;
    return ();
}

1;
#__END__

=head1 NAME

NTS::Utils - Utilitarios Web

=head1 Description

Funcoes simples e rapidas utilizadas em paginas CGI ou modperl

=head1 SYNOPSIS

    use NTS::Utils;

    my %form = NTS::Utils::getForm(eval {my $i = $r->args || $r->content; return $i});

    $r->print($form{field});

=head1 TO DO

no comment

=head1 DIRECTIVE

=head2 getForm()

    %form = NTS::Utils::getForm(eval {my $i = $r->args || $r->content; return $i});

=head1 Authors

=over

=item

Udlei Nattis E<lt>unattis (at) nattis.comE<gt>

=back

=cut

