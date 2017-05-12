package PDL::Audio::Pitches;

require Exporter;

@ISA = qw(Exporter);

$VERSION = 1.0;

=head1 NAME

PDL::Audio::Pitches - All the standard musical pitch names.

=head1 SYNOPSIS

 use PDL::Audio::Pitches;

 print a4;  # prints 440
 print bs3; # prints 261.63

=head1 DESCRIPTION

This module defines (and exports by default(!)) all standard pitch names:

C<cdefgab> with trailing octave, e.g. C<a4>, C<g3>, C<c0>, C<a8>,
C<interleaved "f" and "s", e.g. as4>, C<bf3>, C<fs6>.

=cut

=head1 AUTHOR

Marc Lehmann <schmorp@schmorp.de>

=head1 SEE ALSO

perl(1), L<PDL>, L<PDL::Audio>.

=cut

my $base = 440.0 / (2 ** 4.75);

sub gen($$$) {
   my ($o,$p,$i) = @_;
   my $note = "$p$o";
   my $hz = $base * (2 ** ($o + $i/12));
   eval "sub $note (){ $hz }";
   push @EXPORT, $note;
}

for my $o (0..8) {
   gen $o, 'c', 0; gen $o, 'cs', 1; gen $o, 'df', 1;
   gen $o, 'd', 2; gen $o, 'ds', 3; gen $o, 'ef', 3;
   gen $o, 'e', 4; gen $o, 'ff', 4; gen $o, 'es', 5;
   gen $o, 'f', 5; gen $o, 'fs', 6; gen $o, 'gf', 6;
   gen $o, 'g', 7; gen $o, 'gs', 8; gen $o, 'af', 8;
   gen $o, 'a', 9; gen $o, 'as',10; gen $o, 'bf',10;
   gen $o, 'b',11; gen $o, 'cf',-1; gen $o, 'bs',12;
}

1;
