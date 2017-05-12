package Number::OutlineNumber;
require 5.000;


# Purpose: To Create Outline Numbering
#
# Copyright 2002 Pete M. Wilson (wilsonpm@gamewood.net)
# Version 1.00  (17 Jan 2002)
#
# Originally Developed with ActiveState Perl v 5.6.1 build 631 for Win32.
#
##    This package is free software; you can redistribute it                 ##
##    and/or modify it under the same terms as Perl itself.                  ##

use strict;
use warnings;
use vars qw($VERSION);

$VERSION = '1.00'; # $Date: 2002/01/17 20:28:40 $

use overload
	'++' => \&_inc,
	qw("") => \&_stringify;

sub new {
	my $class = shift;
	my $self = { };
	if (@_) {
		$self->{NUMVAL} = $_[0];
	}
	else {
		$self->{NUMVAL} = "1.";
	}

	return bless $self,$class;
}

# Increment the last (trailing) outline portion
sub _inc {
	my $self = shift;
	my $numval = $self->{NUMVAL};
	if (length($numval) > 0) {
		my $revldp = index(reverse($numval),".",1);
		if ($revldp == -1) {
			$revldp = length($numval);
		}
		my $lastdotpos = length($numval) - $revldp;
		my $newlast = substr($numval,$lastdotpos)+1;

		$self->{NUMVAL} = substr($numval, 0, $lastdotpos) . $newlast . ".";
	}
}

sub _stringify {
	my $self = shift;

	return $self->{NUMVAL};
}

sub indent {
	my $self = shift;
	$self->{NUMVAL} .= "1.";
}

sub outdent {
	my $self = shift;
	my $numval = $self->{NUMVAL};
	my $revldp = index(reverse($numval),".",1);
	if ($revldp == -1) {
		$revldp = length($numval);
	}
	my $lastdotpos = length($numval) - $revldp;

	$self->{NUMVAL} = substr($numval, 0, $lastdotpos);
}

sub last_number {
	my $self = shift;
	my $numval = $self->{NUMVAL};

	my $revldp = index(reverse($numval),".",1);
	if ($revldp == -1) {
		$revldp = length($numval);
	}
	my $lastdotpos = length($numval) - $revldp;

	return substr($numval,$lastdotpos);
}

1;
__END__

=head1 NAME

Number::OutlineNumber - Perl extension for Outline Numbering stored in strings

=head1 SYNOPSIS

  use Number::OutlineNumber;
  my $num = new Number::OutlineNumber;

  print "$num\n";
  $num->indent;
  print "$num\n";
  ++$num;
  print "$num\n";
  $num->outdent;
  print "$num\n";

=head1 DESCRIPTION

Module for creation of Outline Numbering objects that store dotted numbers in strings.
Has operations for incrementing number and indenting to next level and outdenting to
previous level.

=head2 EXPORT

None by default.


=head1 AUTHOR

Pete M. Wilson <lt>wilsonpm@gamewood.net<gt>

=head1 SEE ALSO

L<perl>.

=cut
