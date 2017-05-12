package Music::Tempo;
use strict;

BEGIN {
	use Exporter ();
	use vars qw ($VERSION @ISA @EXPORT);
	$VERSION     = 0.02;
	@ISA         = qw (Exporter);
	@EXPORT      = qw (bpm_to_italian italian_to_bpm bpm_to_ms ms_to_bpm);
}

=head1 NAME

 Tempo - various conversions to and from BPM

=head1 SYNOPSIS

    use Music::Tempo;

    my $marking = bpm_to_italian(50);          # 'Largo'
    my $bpm = italian_to_bpm('Allegro');       # 120
    my $ms = bpm_to_ms(100);		           # 600
    my $bpm = ms_to_bpm(200,8);				   # 120


=head1 DESCRIPTION

 Includes two main functions, converting BPM (Beats Per Minute) to and from ms (milliseconds) and Italian metonome markings.

=head1 METHODS

=head2 bpm_to_italian($bpm)

Takes a BPM marking, and returns an appropriate Italian metronome marking (Lento, Allegro etc. - see below for full list).

=head2 italian_to_bpm($marking)

Takes an Italian metronome marking (Lento, Allegro, Presto etc.) and returns an *average* BPM.

=head2 bpm_to_ms($bpm,$beat)

Converts from BPM to ms. The 'beat' parameter (which defaults to 4) acts as an extra divisor.
For instance, 120 BPM would normally mean 1 crotchet (or 1/4 note) =500ms. 
Passing a beat of '16' would return 125ms, referring to semiquavers (or 1/16 notes).

=head2 ms_to_bpm($ms,$beat)

The reverse of bpm_to_ms.

=head1 TEMPI

The italian tempi are of course approximations. The ranges below have been greatly reduced, and are
presented only as a 'last resort' for automatic machine translation etc. They're roughly based on an
average between Maetzel and Quantz, tweaked for 'standard modern' usage (Allegro=120 etc.).

 Largo       40-59
 Larghetto   60-66
 Adagio      67-72
 Lento       73-78
 Andante     79-88
 Moderato    89-109
 Allegro     110-129
 Vivace      130-149
 Presto      150-190
 Prestissimo 190-220

=head1 TODO

=head1 AUTHOR

 Ben Daglish (bdaglish@surfnet-ds.co.uk)

=head1 BUGS 
 
 None known
 All feedback most welcome.

=head1 COPYRIGHT

 Copyright (c) 2003, Ben Daglish. All Rights Reserved.
 This program is free software; you can redistribute
 it and/or modify it under the same terms as Perl itself.

 The full text of the license can be found in the
 LICENSE file included with this module.

=head1 SEE ALSO

 perl(1).

=cut


my %tempi = (
	'LARGO' => [40,59],
	'LARGHETTO' => [60,66],
	'ADAGIO' => [67,72],
	'LENTO' => [73,78],
	'ANDANTE' => [79,88],
	'MODERATO' => [89,109],
	'ALLEGRO' => [110,129],
	'VIVACE' => [130,149],
	'PRESTO' => [150,190],
	'PRESTISSIMO' => [190,220],
);


sub italian_to_bpm {
	my $name = uc(shift());
	return unless defined $tempi{$name};
	return int(($tempi{$name}[0] + $tempi{$name}[1])/2) + 1;
}
sub bpm_to_italian {
	my $bpm = shift();
	return unless int($bpm);
	return "Too Slow" if $bpm < 40;
	return "Too Fast" if $bpm > 220;
	foreach (keys %tempi) {
		return ucfirst(lc($_)) if ($tempi{$_}[0] <= $bpm  && $bpm <= $tempi{$_}[1]);
	}
}

sub bpm_to_ms {
	my $bpm = shift;
	my $beat = shift || 4;
	return unless (int($bpm) && int($beat));
	return 240000 / ($bpm * $beat);
}
sub ms_to_bpm {
	my $ms = shift;
	my $beat = shift || 4;
	return unless (int($ms) && int($beat));
	return 240000 / ($ms * $beat);
}


1;
