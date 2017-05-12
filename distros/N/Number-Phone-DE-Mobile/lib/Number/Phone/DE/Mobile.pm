#!/usr/bin/perl
#
# module name:	 Number::Phone::DE::Mobile
# version:		 1.1
# date:			 11.01.02
# author:		 karsten pawlik
# authors email: netsrak@cpan.org
#
# Changes:		 v.1.1: the module now returns "invalid" string
#				 if a number is not valid. Module has been
#				 renamed to Number::Phone::DE::Mobile to meet
#				 Perl standards.
#################################################################
=pod

=head1 NAME

Number::Phone::DE::Mobile
Check German Mobile Phone Numbers for validity and
put them into a standard format.

=head1 SYNOPSIS

  use Number::Phone::DE::Mobile qw(checkmsisdn);

  $checkedmsisdn = Number::Phone::DE::Mobile->checkmsisdn($rawmsisdn);

=head1 DESCRIPTION

Number::Phone::DE::Mobile is a simple module to validate German Mobile Phone Numbers
(MSISDNs) and return them in a single format.

regarding the fact, that mobile phone msisdns can contain 7 or 8 digits
behind the area code and also regarding the various msisdn-output formats
on wap gateways, sms-servers etc. i wrote a small perl-module
that transforms all msisdns, no matter what input-format you use, into
one, standard output format:

                        xxyyyzzzzzzzz
where:
x = country code
y = area code
z = subscriber number (either 7 or 8 digits...)

basically there are 10 types of msisdn-notations that are possible at
present and that are supported by the module:
7-digit numbers:

0049___17x_____1234567_____=14 digits

34_____17x_____1234567_____=12 digits

00_____17x_____1234567_____=12 digits

0______17x_____1234567_____=11 digits

_______17x_____1234567_____=10 digits



8-digit numbers:

0049___17x_____12345678____=15 digits

34_____17x_____12345678____=13 digits

00_____17x_____12345678____=13 digits

0______17x_____12345678____=12 digits

_______17x_____12345678____=11 digits


comments:
1) the country code can be any number not starting with a zero.
(this will work for nearly all countries except countries with a 
single digit country code.)

2) the area code can be any 3-digit number starting with
"1" (i.e.: 179, 176, 150, 160, 168 etc...)

3) a leading "+" sign will be translated into two zeros "00"
before its processed

4) special characters like "+","&",";","_","-","." will be deleted from the
msisdn before its processed

5) if the msisdn is not ok, the program returns "invalid".

=over 8

=cut


package Number::Phone::DE::Mobile;
require Exporter;

$VERSION = 1.0;
@ISA	=qw(Exporter);
@EXPORT =qw(checkmsisdn);

sub checkmsisdn {
# check if option has been given. if not print message and quit.
my $self	= shift;
$msisdn	= shift;
if ("$msisdn" eq ""){ die "usage: Number::Phone::DE::Mobile->checkmsisdn(<rawmsisdn>)\n\n"; }

# replace + signs at the beginning with two zeros
$msisdn =~ s/^\+/00/ig;

# delete any blanks, minuses and underscores...
$msisdn =~ s/ |-|_|\;|\&|\+|\.//ig;

# check if msisdn contains only digits
$msisdn_ok = "no";
if ($msisdn =~ /\D+/) {
	$msisdn_ok = "no";
} else {
  # else check if length is valid
  @possible_lengths = (10,11,12,13,14,15);
  $msisdn_len = length($msisdn);
  foreach $pos_len (@possible_lengths) {
	if ($pos_len == $msisdn_len) {
		$msisdn_ok = "yes";
	}
  }
}

# if msisdn is ok check every possible case and transform msisdn if necessary
if ("$msisdn_ok" eq "yes") {
	if ($msisdn =~ /\d{15}$/) {
		if ($msisdn =~ /^00/) { $msisdn =~ s/^..//; }
		return($msisdn);
	}	
	if ($msisdn =~ /\d{14}$/) {
		if ($msisdn =~ /^00/) { $msisdn =~ s/^..//; }
		return($msisdn);
	}	
	if ($msisdn =~ /\d{13}$/) {
		if ($msisdn =~ /^!0\d/) { $msisdn =~ $msisdn; }
		if ($msisdn =~ /^00/) { $msisdn =~ s/^../49/; }
		return($msisdn);
	}	
	if ($msisdn =~ /\d{12}$/) {
		if ($msisdn =~ /^!0\d/) { $msisdn =~ $msisdn; }
		if ($msisdn =~ /^00/) { $msisdn =~ s/^../49/; }
		if ($msisdn =~ /^01/) { $msisdn =~ s/^./49/; }
		return($msisdn);
	}
	if ($msisdn =~ /\d{11}$/) {
		if ($msisdn =~ /^1/) { $msisdn = "49$msisdn"; }
		if ($msisdn =~ /^01/) { $msisdn =~ s/^0/49/; }
		return($msisdn);
	}	
	if ($msisdn =~ /\d{10}$/) { $msisdn =~ s/^/49/; return($msisdn);}
} else {
	# if msisdn is not ok, quit.
	return("invalid");
}
}


=pod

=back

=head1 COPYRIGHT

This module is published under the GPL.

=head1 SEE ALSO

perl(1)

=head1 AUTHOR

Karsten Pawlik
Mailto:	netsrak@cpan.org
Web:	http://www.designlab.de

=cut
