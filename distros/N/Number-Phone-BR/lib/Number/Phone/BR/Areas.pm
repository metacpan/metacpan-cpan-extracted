package Number::Phone::BR::Areas;
use warnings;
use strict;
use utf8;
use base 'Exporter';

our $VERSION = '0.001'; # VERSION

our @EXPORT_OK = qw/
    code2name
    mobile_phone_digits_by_area
/;

my %TABLE = (
    11 => 'SP - Região Metropolitana de São Paulo',
    12 => 'SP - São José dos Campos e Região',
    13 => 'SP - Região Metropolitana da Baixada Santista',
    14 => 'SP - Bauru, Jaú, Marília, Botucatu e Região',
    15 => 'SP - Sorocaba e Região',
    16 => 'SP - Ribeirão Preto, São Carlos, Araraquara e Região',
    17 => 'SP - São José do Rio Preto e Região',
    18 => 'SP - Presidente Prudente, Araçatuba e Região',
    19 => 'SP - Região Metropolitana de Campinas',
    21 => 'RJ - Região Metropolitana do Rio de Janeiro',
    22 => 'RJ - Campos dos Goytacazes e Região',
    24 => 'RJ - Volta Redonda, Petrópolis e Região',
    27 => 'ES - Região Metropolitana de Vitória',
    28 => 'ES - Cachoeiro de Itapemirim e Região',
    31 => 'MG - Região Metropolitana de Belo Horizonte',
    32 => 'MG - Juiz de Fora e Região',
    33 => 'MG - Governador Valadares e Região',
    34 => 'MG - Uberlândia e região',
    35 => 'MG - Poços de Caldas, Pouso Alegre, Varginha e Região',
    37 => 'MG - Divinópolis, Itaúna e Região',
    38 => 'MG - Montes Claros e Região',
    41 => 'PR - Região Metropolitana de Curitiba',
    42 => 'PR - Ponta Grossa e Região',
    43 => 'PR - Londrina e Região',
    44 => 'PR - Maringá e Região',
    45 => 'PR - Cascavel e Região',
    46 => 'PR - Francisco Beltrão, Pato Branco e Região',
    47 => 'SC - Joinville, Blumenau, Balneário Camboriú e Região',
    48 => 'SC - Região Metropolitana de Florianópolis e Criciúma',
    49 => 'SC - Chapecó, Lages e Região',
    51 => 'RS - Região Metropolitana de Porto Alegre',
    53 => 'RS - Pelotas e Região',
    54 => 'RS - Caxias do Sul e Região',
    55 => 'RS - Santa Maria e Região',
    61 => 'DF - Brasília e Região',
    62 => 'GO - Região Metropolitana de Goiânia',
    63 => 'Tocantins',
    64 => 'GO - Rio Verde e Região',
    65 => 'MT - Região Metropolitana de Cuiabá',
    66 => 'MT',
    67 => 'Mato Grosso do Sul',
    68 => 'Acre',
    69 => 'Rondônia',
    71 => 'BA - Região Metropolitana de Salvador',
    73 => 'BA - Itabuna, Ilhéus e Região',
    74 => 'BA - Juazeiro e Região',
    75 => 'BA - Feira de Santana e Região',
    77 => 'BA - Vitória da Conquista e Região',
    79 => 'Sergipe',
    81 => 'Pernambuco',
    82 => 'Alagoas',
    83 => 'Paraíba',
    84 => 'Rio Grande do Norte',
    85 => 'CE - Região Metropolitana de Fortaleza',
    86 => 'PI - Região de Teresina',
    87 => 'PE - Região de Petrolina',
    88 => 'CE - Região de Juazeiro do Norte',
    89 => 'PI - Região de Picos e Floriano',
    91 => 'PA - Região Metropolitana de Belém',
    92 => 'AM - Região de Manaus',
    93 => 'PA - Região de Santarém',
    94 => 'PA - Região de Marabá',
    95 => 'RR - Todos os municípios do estado',
    96 => 'Amapá',
    97 => 'AM - Região de Tefé e Coari',
    98 => 'MA - Região Metropolitana de São Luís',
    99 => 'MA - Região de Imperatriz',
);

sub code2name { $TABLE{ "$_[0]" } }

sub mobile_phone_digits_by_area {
    my ($area) = @_;

    my $current_year = _get_current_year();

    # as of today, in these area codes, all mobile phones have 9 digits:
    my %nine_digits = map { $_ => 1 } qw/
        11 12 13 14 15 16 17 18 19
        21 22 24 27 28
    /;

    return 9 if $nine_digits{$area};

    my %codes_by_year = (
        2014, [ qw/91 92 93 94 95 96 97 98 99/ ],
        2015, [ qw/31 32 33 34 35 37 38 71 73 74 75 77 79 81 82 83 84 85 86 87 88 89/ ],
        2016, [ qw/41 42 43 44 45 46 47 48 49 51 53 54 55 61 62 63 64 65 66 67 68 69/ ],
    );

    for my $year (sort keys %codes_by_year) {
        last if $current_year <= $year;

        for (@{ $codes_by_year{$year} }) {
            $nine_digits{$_} = 1;
        }

        return 9 if $nine_digits{$area};
    }

    return 8;
}

sub _get_current_year { 1900 + (localtime(time()))[5] }

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Number::Phone::BR::Areas

=head1 DESCRIPTION

Utilities to handle local areas (prefixes and names) for Brazilian telephone numbers.

=head1 METHODS

All of these methods are exported upon request:

=head2 mobile_phone_digits_by_area($code)

=head3 Arguments:

=over 4

=item *

$code: the code of the area (DDD)

=back

=head3 Return value:

=over 4

=item *

Integer 8 or 9, according to the area, based on current date.

=back

Brazil mobile phones are migrating to 9 digits. Not all areas have migrated,
but they will by the end of 2016. This function returns whether a given area
has 8 or 9 digits for its mobile phone numbers.

=head2 code2name($code)

=head3 Arguments:

=over 4

=item *

$code: the code of the area (DDD)

=back

=head3 Return value:

=over 4

=item *

The name of the area.

=back

Returns the name of the region of a given code.

=head1 AUTHOR

André Walker <andre@andrewalker.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by André Walker.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
