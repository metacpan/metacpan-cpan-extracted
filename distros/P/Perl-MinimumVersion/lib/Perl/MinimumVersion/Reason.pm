package Perl::MinimumVersion::Reason;
$Perl::MinimumVersion::Reason::VERSION = '1.40';
# Simple abstraction for a syntax limitation.
# It contains the limiting version, the rule responsible, and the
# PPI element responsible for the limitation (if any).

use 5.006;
use strict;
use warnings;

sub new {
	my $class = shift;
	return bless { @_ }, $class;
}

sub version {
	$_[0]->{version};
}

sub rule {
	$_[0]->{rule};
}

sub element {
	$_[0]->{element};
}

sub explanation {
	$_[0]->{explanation};
}

1;
