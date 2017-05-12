package Money::ChangeMaker::Presets;

require 5;
use strict;
use Money::ChangeMaker::Denomination;

my $ret = undef;

sub _gen_presets_hash {
	return $ret if $ret;
	# Read the data from the POD!  TorgoX++
	
	my $data;
	{
		local $/;
		$data = <Money::ChangeMaker::Presets::DATA>;
	}
	for my $section (split(/=head/, $data)) {
		next unless $section =~ /^2 (\S+).*?Value +Name +Plural\s*-+\n(.*)/s;
		my $ref = [];
		$ret->{$1} = $ref;
		for my $line (split(/\n/, $2)) {
			$line =~ s/^\s+//;
			my @elements = split(/ {2,}/, $line);
			push(@{$ref}, new Money::ChangeMaker::Denomination(@elements));
		}
	}
	return $ret;
}

1;

__DATA__

=head1 NAME

Money::ChangeMaker::Presets - Contains preset currency sets for Money::ChangeMaker

=head1 SYNOPSIS

	See L<Money::ChangeMaker>

=head1 DESCRIPTION

Simply contains the preset monetary sets used by the L<Money::ChangeMaker>
module.  In general, users should not interact with this module at all, it
is simply provided as separate so that users may modify it in their own
installation to add/modify existing preset sets.

=head1 METHODS

There are no public methods in this module.

=head1 CAVEATS

When working with monetary amounts, it is common to want to represent them
in the same terms as they are represented in life -- e.g. 12.45 to represent
twelve dollars and 45 cents.  However, in perl, floating point numbers
are subject to certain inherent inconsitencies and as such should really
be avoided when possible.  It is therefore better to work only with
integer values, by making sure that the smallest unit in a monetary set
is represented by 1, not by 0.01.  This is the standard as used by all
presets in this module.

More details about floating point errors are available at
http://www.lahey.com/float.htm

=head1 Available Presets

=head2 Canada

The base unit for this set is the penny.  Thus, twenty dollars is represented
by 2000 and fifty cents by 50.

	Value       Name               Plural
	----------------------------------------
	10000       hundred dollar bill
	2000        twenty dollar bill
	1000        ten dollar bill
	500         five dollar bill
	200         two dollar coin
	100         one dollar coin
	25          quarter
	10          dime
	5           nickel
	1           penny              pennies


=head2 India

The base unit for this set is the rupee.  This means that there are some
floating point units, for the paisa coins -- they are rare enough that
I decded to simplify the currency set rather than avoid a
rare possible error case.

	Value       Name               Plural
	----------------------------------------
	1000        thousand rupee note
	500         five hundred rupee note
	100         one hundred rupee note
	50          fifty rupee note
	20          twenty rupee note
	10          ten rupee note
	5           five rupee note
	2           two rupee note
	1           rupee coin
	0.5         50 paise coin
	0.25        25 paise coin


=head2 UK

The base unit for this set is the penny.  Thus, twenty pounds is represented
by 2000 and fifty pence by 50.

	Value       Name               Plural
	----------------------------------------
	5000        fifty pound note
	2000        twenty pound note
	1000        ten pound note
	500         five pound note
	200         two pound coin
	100         one pound coin
	50          fifty pence coin
	20          twenty pence coin
	10          ten pence coin
	5           five pence coin
	2           two pence coin
	1           penny              pence


=head2 USA

The base unit for this set is the penny.  Thus, twenty dollars is represented
by 2000 and fifty cents by 50.

	Value       Name               Plural
	----------------------------------------
	10000       hundred dollar bill
	5000        fifty dollar bill
	2000        twenty dollar bill
	1000        ten dollar bill
	500         five dollar bill
	100         dollar bill
	25          quarter
	10          dime
	5           nickel
	1           penny              pennies


=head2 Australia

The base unit for this set is the cent.  Thus, twenty dollars is represented
by 2000 and fifty cents by 50.

	Value       Name               Plural
	----------------------------------------
	10000       hundred dollar note
	5000        fifty dollar note
	2000        twenty dollar note
	1000        ten dollar note
	500         five dollar note
	200         two dollar coin
	100         one dollar coin
	50          fifty cent piece
	20          twenty cent piece
	10          ten cent piece
	5           five cent piece


=head2 Euro

The base unit for this set is the cent.  Thus, twenty euros is represented
by 2000 and fifty cents by 50.

	Value       Name               Plural
	----------------------------------------
	50000       five hundred euro note
	20000       two hundred euro note
	10000       one hundred euro note
	5000        fifty euro note
	2000        twenty euro note
	1000        ten euro note
	500         five euro note
	200         two euro coin
	100         one euro coin
	50          fifty cent coin
	20          twenty cent coin
	10          ten cent coin
	5           five cent coin
	2           two cent coin
	1           one cent coin


=head1 Adding Sets

In this release, there is no programmatic method for adding new currency sets
to the preset data, apart from directly modifying the documentation of this
module.  If there is sufficient demand, I will add functionality to allow
people to add new sets at run-time.  Instead, I suggest you use one of these
methods instead:

You can modify the contents of the Presets.pm file on your local installation.
If you do this, simply follow the pattern as already laid out in the file.
Keep in mind that preset lists must be created in descending value order.  When
dynamic currency sets are added, they are sorted, so this is not important
in that case.  However, when reading from presets, it assumes that the
units are already in order, as an optimization.

Preferably, if you think that the monetary set would be of use to more than
just yourself, you can send it to me at F<avi@finkel.org>.  There is
no specific format I need it in, I just ask that any submissions are complete,
accurate and detailed.  If possible, include alternate "slang" names for
any currency units, include units that are no longer in circulation (but
please indicate them as such,) and any other notes about the units that may
be of interest.  Any submissions will be greatly appreciated and appropriately
credited.

Please keep in mind that ChangeMaker objects do not B<need> to built using
presets.  If you are building denomination sets dynamically, they should
be stored in your own code and given to the ChangeMaker object using the
'denomination' method.


=head1 AUTHOR

Copyright 2006 Avi Finkel <F<avi@finkel.org>>

This package is free software and is provided "as is" without express
or implied warranty.  It may be used, redistributed and/or modified
under the terms of the Perl Artistic License (see
http://www.perl.com/perl/misc/Artistic.html)

=cut
