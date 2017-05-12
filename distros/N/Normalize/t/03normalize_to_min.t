#!perl -T
use warnings;
use strict;

use Test::More tests => 6;
use Normalize;

#test1
my $norm = Normalize->new( 'round_to' => 0.001 );
my %weight_rate = (
	'Professor'    => 70.2,
	'Bender'       => 600,
	'Dr. Zoidberg' => 200,
	'Fray'         => 120
);
my $res = $norm->normalize_to_min( \%weight_rate, { min_default => 0.001 } );

ok( $res && ref($res) eq 'HASH' && $res == \%weight_rate,
	'test normalize_to_min return hashref result' );
ok(
	$weight_rate{'Professor'} == 1
	  && $weight_rate{'Bender'} == 0.117
	  && $weight_rate{'Dr. Zoidberg'} == 0.351
	  && $weight_rate{'Fray'} == 0.585,
	'test normalize_to_min hashref score results'
);

=head2 print results test normalized score results
foreach my $key (sort {$weight_rate{$b} <=> $weight_rate{$a}} keys %weight_rate)
{
	print "#$weight_rate{$key}\t$key\n";
}
#1.000	Professor
#0.585	Fray
#0.351	Dr. Zoidberg
#0.117	Bender
=cut

my @array = ( 10.02, 89, 9.2 );
my $res2 = $norm->normalize_to_min( \@array );
ok( $res2 && ref($res2) eq 'ARRAY' && $res2 == \@array,
	'test normalize_to_min return arrayref result' );
ok( $array[0] == 0.918 && $array[1] == 0.103 && $array[2] == 1.000,
	'test normalize_to_min arrayref score results' );

=head2 print results test arrayref normalized score results
foreach my $a (@array)
{
	print "#$a\n";
}
#0.918
#0.103
#1.000
=cut

#test whith zero values
my %zerov = ( 'zero' => 0, 'zero2' => 0, 'min' => 0.001, 'num' => 0.09 );
$norm->normalize_to_min( \%zerov, { min_default => 0.01 } );
ok(
	$zerov{'min'} == 1.000
	  && $zerov{'zero'} == 1.000
	  && $zerov{'zero2'} == 1.000
	  && $zerov{'num'} == 0.011,
	'test normalize_to_min hashref whith zero values'
);

=head2 print results test hashref whith zero values
foreach my $key (sort {$zerov{$b} <=> $zerov{$a}} keys %zerov)
{
	print "#$zerov{$key}\t$key\n";
}
#1.000	min
#1.000	zero
#1.000	zero2
#0.011	num
=cut

my @zeroa = ( 0, 0.001, 0.0, 0.09 );
$norm->normalize_to_min( \@zeroa, { min_default => 0.01 } );
ok(
	$zeroa[0] == 1.000
	  && $zeroa[1] == 1.000
	  && $zeroa[2] == 1.000
	  && $zeroa[3] == 0.011,
	'test normalize_to_min arrayref whith zero values'
);

=head2 print results test arrayref whith zero values
foreach my $a (@zeroa)
{
	print "#$a\n";
}
#1.000
#1.000
#1.000
#0.011
=cut

