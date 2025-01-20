# ABSTRACT: Make a tidy table of features

use strict;
use warnings;
use Config::General;
use Text::TabularDisplay;
use Data::Section -setup;

my $string = __PACKAGE__->section_data( 'config' );
my $conf = Config::General->new( -String => $$string );
my %config = $conf->getall;
my @modules = sort keys %{ $config{module} };
my @features = sort { $config{features}{ $a } cmp $config{features}{ $b } } keys %{ $config{features} };
my $table = Text::TabularDisplay->new( 'Feature', @modules );
for my $feature ( @features ) {
	my $feature_name = $config{features}{ $feature };
	my @list = map { $config{module}{ $_ }{ $feature } } @modules;
	$table->add( $feature_name, @list );
}
print $table->render, "\n\n";
for my $module ( @modules ) {
	my $module_name = $config{module}{ $module }{name};
	printf "  %-5s = %s\n", $module, $module_name;
}
print "\n";

__DATA__
__[config]__

<features>
	auto           Automatic parameter calculation based on the data
	bad            Bad value support
	callbacks      Define and use callbacks to apply to the bins
	data           Native data type
	dims           Maximum number of dimensions
	implementation Core implementation
	interface      Interface style
	multiple       Can bin multiple variables at once
	overflow       Has overflow and underflow bins by default
	performance    Performance
	piecewise      Allows piecewise data processing
	resampling     Allows resampling the histogram
	serialization  Facilities for data structure serialization
	broadcasting   Uses PDL broadcasting
	variable       Variable-width bins
	weight         Support for weighted histograms
</features>

<module MGH>
	name           Math::GSL 0.26 (Math::GSL::Histogram and Math::GSL::Histogram2D)

	auto           -
	bad            -
	callbacks      -
	data           Scalars
	dims           2
	implementation C
	interface      Proc.
	multiple       -
	overflow       -
	performance    Low
	piecewise      -
	resampling     -
	serialization  X
	broadcasting   -
	variable       X
	weight         X
</module>

<module MH>
	name           Math::Histogram 1.03

	auto           -
	bad            -
	callbacks      -
	data           Arrays
	dims           N
	implementation C
	interface      OO
	multiple       -
	overflow       X
	performance    Medium
	piecewise      -
	resampling     -
	serialization  X
	broadcasting   -
	variable       X
	weight         X
</module>

<module MSHXS>
	name           Math::SimpleHisto::XS 1.28

	auto           -
	bad            -
	callbacks      -
	data           Arrays
	dims           1
	implementation C
	interface      OO
	multiple       -
	overflow       X
	performance    High
	piecewise      -
	resampling     X
	serialization  X
	broadcasting   -
	variable       X
	weight         X
</module>

<module PDL>
	name           PDL 2.4.11

	auto           X
	bad            X
	callbacks      -
	data           NDArrays
	dims           2
	implementation C
	interface      Proc.
	multiple       -
	overflow       -
	performance    Very high
	piecewise      -
	resampling     X
	serialization  X
	broadcasting   X
	variable       -
	weight         X
</module>

<module PND>
	name           PDL::NDBin 0.017

	auto           X
	bad            X
	callbacks      Perl+C
	data           NDArrays
	dims           N
	implementation C/Perl
	interface      OO+Proc.
	multiple       X
	overflow       -
	performance    High
	piecewise      X
	resampling     -
	serialization  -
	broadcasting   -
	variable       X
	weight         -
</module>
