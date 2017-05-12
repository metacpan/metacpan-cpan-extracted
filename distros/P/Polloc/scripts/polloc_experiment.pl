#!perl

use strict;
use Bio::Polloc::LocusIO;
use Bio::Polloc::Genome;
use Bio::Polloc::TypingIO;

use Pod::Usage;

my $cnf = shift @ARGV; # Configuration file
my $gff = shift @ARGV; # Input GFF containing the loci in a group
my $out = shift @ARGV; # Output PNG image
pod2usage(1) unless $cnf and $gff and $out;

my $genomes = Bio::Polloc::Genome->build_set(-files=>\@ARGV);

my $locusIO = Bio::Polloc::LocusIO->new(-file=>$gff, -format=>'gff');
my $loci = $locusIO->read_loci(-genomes=>$genomes);
my $typing = Bio::Polloc::TypingIO->new(-file=>$cnf)->typing;
$typing->scan(-locigroup=>$loci);
my $graph = $typing->graph;
open PNG, '>', $out or die $0.': Unable to open '.$out.': '.$!;
binmode PNG;
print PNG $graph->png;
close PNG;
exit;

__END__

=pod

=head1 AUTHOR

Luis M. Rodriguez-R < lmrodriguezr at gmail dot com >

=head1 DESCRIPTION

Simulates an experiment defined in a C<.bme> file (C<[Typing]> section) using
a list of loci as reference, and generates a graphical representation.

=head1 LICENSE

This script is distributed under the terms of
I<The Artistic License>.  See LICENSE.txt for details.

=head1 SYNOPSIS

C<perl polloc_detect.pl> B<arguments>

The arguments must be in the following order:

=over

=item Configuration

The configuration file (a .bme or .cfg file).

=item Input GFF

A path to the GFF file containing the reference loci.

=item Output PNG

A path to the PNG image to be generated.

=item Inseqs

All the following arguments will be treated as input files.  Each
file is assumed to contain a genome (that can contain one or more
sequence) in [multi-]fasta format.

=back

Run C<perl polloc_vntrs.pl> without arguments to see the help
message.

=head1 SEE ALSO

=over

=item *

L<Bio::Polloc::RuleIO>

=item *

L<Bio::Polloc::LocusIO>

=back

=cut



