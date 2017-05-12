#!/usr/bin/perl

use Getopt::Long ();
use Pod::Usage ();
use charnames ();
use strict;

our $VERSION;
our %options;
$VERSION = '0.01';

# Gets options from command line
if ( ! Getopt::Long::GetOptions(\%options, 'debug:i','help','file=s@','input-enc=s','output-enc=s') ) {
  Pod::Usage::pod2usage(-verbose => 1);
  exit(1);
}

# --help command
if ( $options{'help'} ) {
  Pod::Usage::pod2usage(-verbose => 2);
  exit(0);
}

$options{'input-enc'} ||= 'iso-8859-1';
$options{'output-enc'} ||= 'iso-8859-1';

my %map=();
for my $l (qw(A E I O U)) {
  for my $a (qw(ACUTE GRAVE)) {
    $map{chr(charnames::vianame("LATIN SMALL LETTER $l WITH $a"))}='E<'.lc($l).lc($a).'>';
    $map{chr(charnames::vianame("LATIN CAPITAL LETTER $l WITH $a"))}='E<'.uc($l).lc($a).'>';
  }
}
my $pattern='['.(join '',keys %map).']';

my @files;
if ( ref $options{file} eq 'ARRAY' ) {
  foreach my $file ( @{$options{file}} ) {
    $file =~ s/^\s+//g;
    $file =~ s/\s+$//g;
    push(@files, split(/\s*,\s*/,$file));
  }
}

for (@files) {
  rename $_ => "$_.bak";
  open my $in,"<:encoding($options{'input-enc'})","$_.bak";;
  open my $out,">:encoding($options{'output-enc'})",$_;

  while (<$in>) {
    s{($pattern)}{$map{$1}}ge; #};
    s{E'}{E<Egrave>}g;
    print $out $_;
  }
}

unless (@files) {
  binmode STDIN,":encoding($options{'input-enc'})";
  binmode STDOUT,":encoding($options{'output-enc'})";
  while (<STDIN>) {
    s{($pattern)}{$map{$1}}ge; #};
    s{E'}{E<Egrave>}g;
    print $_;
  }
}

=pod

=head1 NAME

podenc.pl - Perl script per l'encoding dei caratteri accentati nel pod

=head1 SYNOPSIS

   %> perl podenc.pl [command] [options]

=head1 DESCRIPTION

F<podenc.pl> e' un script Perl che effettua l'encoding dei caratteri 
accentati presenti nel pod tramite la codifica EE<lt>...E<gt>.

=head1 ARGUMENTS

=over 4

=item * -h, --help

Mostra l'help a linea di comando ed esce

=item * -f, --file

Consente di specificare uno più file per cui si vuole eseguire l'encoding.
Il comando può essere usato una o più volte:

   --file=file_1 --file=file_2

oppure è possibile specificare più nomi in una sola occorrenza separandoli
da virgola:

   --file="file_1,file_2"

Spazi inziali e finali vengono ignorati:

   --file="file_1 , file_2" --file=" file_3    "

sono comandi validi.

Se non specificato, viene codificato lo STDIN.

=item * --input-enc

Imposta la codifica di open del file originale (lettura). Per default è
'iso-8859-1'

=item * --outut-enc

Imposta la codifica di open del file encodato (scrittura). Per default è
'iso-8859-1'

=back

=head1 EXAMPLES

   %> perl podenc.pl 

   %> perl podenc.pl --file=file.pod

=head1 SEE ALSO

charmanes

=head1 AUTHORS

Gianni Ceccarelli, E<lt>dakkar [at] thenautilus.netE<gt>.
Enrico Sorcinelli E<lt>bepi [at] perl.itE<gt> added command line interface.

=head1 BUGS

Inviare bug reports e commenti a: E<lt>dakkar [at] thenautilus.netE<gt>. In
ogni report indicate per favore la versione del modulo, la versone del Perl, il
nome e la versione del vostro WebServer e sistema operativo. Se il problema e'
anche browser dipendente, indicate anche nome e versione del browser.

=head1 COPYRIGHT

Copyright (C) 2005 Perl.it

=cut
