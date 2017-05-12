package 
    Net::FileMaker::Error::IT::XSLT;

use strict;
use warnings;

=head1 NAME

Net::FileMaker::Error::IT::XML - Error strings for FileMaker Server XSLT interface in Italian.

=head1 INFO

The error codes supported by this module were plucked from the FileMaker documentation on XML/XSLT, and appear valid for FileMaker Server 10.

=head1 SEE ALSO

L<Net::FileMaker::Error>

=cut

my $error_codes = {

    '-1'   => "Errore sconosciuto",
    0      => "Nessun errore",
    10000  => "Nome instestazione non valido",
    10001  => "Il codice status HTTP non è valido",
    10100  => "Errore di sessione sconosciuto",
    10101  => "Il nome della sessione è già in uso",
    10102  => "Non posso accedere alla sessione - probabilmente non esiste",
    10103  => "Sessione scaduta",
    10104  => "L'oggetto della sessione non esiste",
    10200  => "Messaggio di errore sconosciuto",
    10201  => "Errore di formattazione sconosciuto",
    10202  => "Errore nei campi SMTP ",
    10203  => "Errore “Al Campo”",
    10204  => "Errore “Dal Campo”",
    10205  => "Errore “Campo CC ”",
    10206  => "Errore “Campo BCC”",
    10207  => "Errore “Campo Oggetto”",
    10208  => "Errore “Campo Inoltra”",
    10209  => "Errore nel corpo della email",
    10210  => "Errore ricorsivo - tentativo di chiamata a send_email() dentro un foglio di stile XSLT di una email",
    10211  => "Errore di autenticazione SMTP - login fallito o errato metodo di autenticazione",
    10212  => "Utilizzo non valido di una funzione - tentativo di chiamata a set_header(), set_status_code() o set_cookie() dentro un foglio di stile XSLT di una email",
    10213  => "Il server SMTP non è valido o non sta funzionando.",
    10300  => "Errore di formattazione sconosciuto",
    10301  => "Formato data-tempo non valido",
    10302  => "Formato data non valido",
    10303  => "Formato tempo non valido",
    10304  => "Formato giorno non valido",
    10305  => "Formattazione errata per la stringa data-tempo",
    10306  => "Formattazione errata per la stringa data",
    10307  => "Formattazione errata per la stringa tempo",
    10308  => "Formattazione errata per la stringa giorno",
    10309  => "Codifica testo non supportata",
    10310  => "Codifica URL non supportata",
    10311  => "Errore nel pattern dell'Espressione Regolare"
    
};

sub new
{
    my $class = shift;
    $class = ref($class) || $class;

    my $self = { };
    return bless $self, $class;
}

sub get_string
{
    my ($self, $error_code) = @_;
    return $error_codes->{$error_code};
}

1; # End of Net::FileMaker::Error::IT::XSLT
