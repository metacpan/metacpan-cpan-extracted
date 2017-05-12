package PagSeguro::API::Util;
use Exporter 'import';
our @EXPORT = qw(camelize decamelize);

# camelize
sub camelize {
    my $str = shift;
    return join '', map { 
        ucfirst lc 
    } split '_', $str;
}

# decamelize
sub decamelize {
    my $str = shift;
    $str =~ s/^([A-Z])(.*)$/lc($1).$2/e;

    return join '', map { 
        s/([A-Z])/_$1/; lc;  
    } split '', $str;
}

1;
__END__

=encoding utf8

=head1 NAME

PagSeguro::API::Util - Classe com funcionalidades uteis a toda a implementação

=head1 SYNOPSIS

    use PagSeguro::API::Util;

    my $camelize = camelize 'my_string';
    say $camelize; # MyString

    my $decamelize = decamelize 'MyString';
    say $decamelize; # my_string

=head1 DESCRIPTION

Esta classe possui algumas funcionalidades implementadas para ajudar a resolver
problemas comuns ou aprimorar a experiência com o uso desta implementação.


=head1 METODOS

Esta módulo exporta as seguintes subs...

=head2 camelize

    my $camelize = camelize 'my_string';
    say $camelize; # MyString

Transforma uma string no formato C<< minha_string >> para uma string em Camel
Case (MinhaString).

=head2 decamelize

    my $decamelize = decamelize 'MyString';
    say $decamelize; # my_string

Transforma uma string no formato C<< MinhaString >> para uma string em Snake
Case (minha_string).


=head1 AUTHOR

Daniel Vinciguerra <daniel.vinciguerra@bivee.com.br>
