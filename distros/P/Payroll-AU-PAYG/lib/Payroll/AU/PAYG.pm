# Payroll::AU::PAYG.
#
# Paul Fenwick <pjf@cpan.org>, August 2003.
#
# This module computes PAYG withholding for Australian workers.
#
# This is a cheat, it simply queries the ATO's on-line calcuator.
#
# The interface should be fleshed out and properly defined.
#
# Anyone who wants to become the maintainer of this module and raise
# to fame and fortune should get in contact with me directly at
# pjf@cpan.org

package Payroll::AU::PAYG;
use strict;
use warnings;

use LWP::UserAgent;

our $VERSION = 0.01;

my %defaults = (
	CalculatorType			=> 1,
	PayeeName			=> "Employee",
	TFNABNProvided			=> "Y",
	TFNABNExempt			=> "N",
	AustralianResident		=> "Y",
	TaxFreeThresholdClaimed		=> "Y",
	RebateAndFTAAmountClaimed	=> 0,
	MedicareVariation		=> 0, 
	MedicareReducedRate		=> "N",
	HasSpouse			=> "N",
	CombinedIncLessAmtRR		=> "N",
	DependentChildrenClaimed	=> 0,
	CalculationPeriod		=> 1,
	GrossEarnings			=> 0,
	HECSDebt			=> "N",
	SFSSDebt			=> "N",
	EntitledAnnualLeaveLoading	=> "N",
);

my %mappings = (
	CalculatorType => {
		individual => 0,
		labour => 1,
		voluntary => 2,
	},
	CalculationPeriod => {
		weekly => 0,
		fortnightly => 1,
		monthly => 2,
		quarterly => 3
	},
);

my %fields = (
	gross    => qr/Gross \w+ Earnings/,
	tax      => qr/Tax Applicable/,
	rebates  => qr/Less Rebates and Family Tax Benefit/,
	medicare => qr/Less Medicare Levy Adjustment/,
	withheld => qr/Tax Withheld Amounts/,
	net      => qr/Net Pay/,
);

our $ONLINE_CALC = "http://www.ato.gov.au/scripts/taxcalc/calculate_tax.asp";

# Really just a stub right now.
sub new {
	my $class = shift;
	return bless({},$class);
}

# Actually figure out the amounts and return them.
sub calculate {
	my ($this, %args) = @_;
	%args = (%defaults, %args);
	
	# Set the UserAgent if we don't already have one.
	my $ua = $this->{UserAgent} ||= LWP::UserAgent->new;
	
	# For some reason we need to pretend to be Mozilla, not
	# LWP.  The ATO doesn't like agents it hasn't heard of.
	my $response = $ua->post($ONLINE_CALC,\%args,
		"User-Agent" => "Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.0.0) Gecko/20020606",
	);

	unless ($response->is_success) {
		die "Failed ".__PACKAGE__." calculate -- ".$response->error_as_HTML;
	}

	my $content = $response->content;

	my %return = ();

	foreach my $heading (keys %fields) {
		($return{$heading}) = $content =~ 
			m!
				$fields{$heading}	# Our heading
				[^\$]+?			# Non-dollars
				\$([\d,]+\.\d\d)	# The amount.
				</(?i:td)>		# Close tag.
			!sx;
		$return{$heading} =~ tr/,//d;
	}

	return \%return;
}

1;
