package MySQL::ORM::Generate::AttributeMaker;

our $VERSION = '0.01';

use Modern::Perl;
use Moose;
use namespace::autoclean;
use Method::Signatures;
use Data::Printer alias => 'pdump';

##############################################################################
# required attributes
##############################################################################

##############################################################################
# optional attributes
##############################################################################

##############################################################################
# private attributes
##############################################################################

##############################################################################
# methods
##############################################################################

method make_attribute (
	Str      :$name,
	ArrayRef :$comments,
	Str      :$is,
	Str      :$isa,
	Str      :$trigger,
	Str      :$default,
	Bool     :$no_init_arg,
	Bool     :$lazy,
	Str      :$builder,
	Bool     :$required
  ) {

	my $text;
	$text .= "has $name => (\n";

	foreach my $comment (@$comments) {
		$text .= "## $comment\n";
	}

	$text .= "is => '$is',\n";
	$text .= "isa => '$isa',\n";
	$text .= "trigger => $trigger,\n" if $trigger;
	$text .= "init_arg => undef,\n" if $no_init_arg;
	$text .= "default => $default,\n" if $default;
	$text .= "lazy => 1,\n" if $lazy;
	$text .= "builder => '$builder',\n" if $builder;
	$text .= "required => 1,\n" if $required;
	$text .= ");\n";

	return $text;
}

##############################################################################
# private methods
##############################################################################

1;
