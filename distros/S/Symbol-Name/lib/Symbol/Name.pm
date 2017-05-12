package Symbol::Name;

use 5.008008;
use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Symbol::Name ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'test' => [ qw(
	inSpanish
    supportedSpanishSymbols
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'test'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.9';


# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

Symbol::Name - Perl extension for the name of symbols.

=head1 SYNOPSIS

  use Symbol::Name;
  $name = Symbol::Name::inSpanish($symbol);

=head1 DESCRIPTION

Symbol::Name converts a symbol character to its name. Currently it only supports spanish.


=head2 EXPORT

None by default.

=head1 SEE ALSO


=head1 AUTHOR

Alberto Montero, E<lt>alberto@E<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Alberto Montero

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut

sub _getSpanishNames {
    my %spanishNames = ('a' => 'a',
                    'á' => 'a con acento',
                    'b' => 'be',
                    'c' => 'ce',
                    'd' => 'de',
                    'e' => 'e',
                    'é' => 'e con acento',
                    'f' => 'efe',
                    'g' => 'ge',
                    'h' => 'hache',
                    'i' => 'i',
                    'í' => 'i con acento',
                    'j' => 'jota',
                    'k' => 'ka',
                    'l' => 'ele',
                    'm' => 'eme',
                    'n' => 'ene',
                    'ñ' => 'eñe',
                    'o' => 'o',
                    'ó' => 'o con acento',
                    'p' => 'pe',
                    'q' => 'cu',
                    'r' => 'erre',
                    's' => 'ese',
                    't' => 'te',
                    'u' => 'u',
                    'ú' => 'u con acento',
                    'ü' => 'u con diéresis',
                    'v' => 'uve',
                    'w' => 'uve doble',
                    'x' => 'equis',
                    'y' => 'i griega',
                    'z' => 'zeta',
    # #
                    '0' => 'cero',
                    '1' => 'uno',
                    '2' => 'dos',
                    '3' => 'tres',
                    '4' => 'cuatro',
                    '5' => 'cinco',
                    '6' => 'seis',
                    '7' => 'siete',
                    '8' => 'ocho',
                    '9' => 'nueve',
    # #
                    '+' => 'más',
                    '=' => 'igual a',
                    '%' => 'por ciento',
    #
                    '€' => 'euros',
                    '$' => 'dólares',
                    '¢' => 'céntimos',
    # #
                    '\@'=> 'arroba',
    # #
                    '/' => 'barra',
                    '\\'=> 'barra',
    # #
                    '.' => 'punto',
                    ',' => 'coma',
                    ';' => 'punto y coma',
                    '\"'=> 'comillas',
                    ':' => 'dos puntos',
    # #
                    '*' => 'asterisco',
                    '#' => 'almohadilla',
    # #
                    '>' => 'mayor que',
                    '<' => 'menor que',
    # #
                    '_' => 'guión bajo');
    return \%spanishNames;
}

=item inSpanish

Return the spanish name of the given symbol or undef if it is not a symbol.
=cut
sub inSpanish($) {
    my $symbol = shift;

    return "euros" if ($symbol eq '€');
    return "dólares" if ($symbol eq '$');
    return "céntimos" if ($symbol eq '¢');

    $symbol =~ tr/A-ZÁ-ÚÑÜ/a-zá-úñü/;

    return _getSpanishNames()->{$symbol};
} 

=item supportedSpanishSymbols

Return a list of the supported spanish symbols.
=cut
sub supportedSpanishSymbols {
    return [keys %{_getSpanishNames()}];
} 
