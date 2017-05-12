#!perl -T
use warnings;
use strict;

use Test::More tests => 4;
use Normalize;

#test1
my $norm = Normalize->new( 'round_to' => 0.001 );
my %iq_rate = ('Professor' => 125.12, 'Bender' => 64, 'Dr. Zoidberg' => 28.6, 'Fray' => 13);
my $res = $norm->normalize_to_max( \%iq_rate );

ok( $res && ref($res) eq 'HASH' && $res == \%iq_rate,
	'test normalize_to_max return hashref result' );

ok(
	$iq_rate{'Professor'} == 1.000
	  && $iq_rate{'Bender'} == 0.512
	  && $iq_rate{'Dr. Zoidberg'} == 0.229
	  && $iq_rate{'Fray'} == 0.104,
	'test normalize_to_max hashref score results'
);

#=head2 print results test normalized score results
print "\niq rate: larger iq is better\n";
foreach my $key (sort {$iq_rate{$b} <=> $iq_rate{$a}} keys %iq_rate)
{
	print "#$iq_rate{$key}\t$key\n";
}
#1.000	Professor
#0.512	Bender
#0.229	Dr. Zoidberg
#0.104	Fray
#=cut

my @array = ( 10.02, 89, 9.2 );
my $res2 = $norm->normalize_to_max( \@array );
ok( $res2 && ref($res2) eq 'ARRAY' && $res2 == \@array,
	'test normalize_to_max return arrayref result' );
ok( $array[0] == 0.113 && $array[1] == 1.000 && $array[2] == 0.103,
	'test normalize_to_max arrayref score results' );

=head2 print results test arrayref normalized score results
foreach my $a (@array)
{
	print "#$a\n";
}
#0.113
#1.000
#0.103
=cut

my %weight_rate = (
	'Professor'    => 70.2,
	'Bender'       => 600,
	'Dr. Zoidberg' => 200,
	'Fray'         => 120
);
$norm->normalize_to_min( \%weight_rate, { min_default => 0.001 } );

foreach my $key (sort {$weight_rate{$b} <=> $weight_rate{$a}} keys %weight_rate)
{
	print "#$weight_rate{$key}\t$key\n";
}

my %summary_score = map { $_ => $weight_rate{$_} + $iq_rate{$_} } keys %iq_rate;
$norm->normalize_to_max( \%summary_score );

print "\n#summary score:\n";
foreach my $key (sort {$summary_score{$b} <=> $summary_score{$a}} keys %summary_score)
{
	print "#$summary_score{$key}\t$key\n";
}
#summary score:
#1.000	Professor
#0.344	Fray
#0.315	Bender
#0.290	Dr. Zoidberg


