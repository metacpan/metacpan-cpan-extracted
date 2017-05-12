package Palm::DateTime;
#
# ABSTRACT: Deal with various Palm OS date/time formats
#
#	Copyright (C) 2001-2002, Alessandro Zummo <a.zummo@towertech.it>
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.


use strict;

use Exporter;
use POSIX;
use vars qw($VERSION);

# One liner, to allow MakeMaker to work.
$VERSION = '1.400';
# This file is part of Palm 1.400 (March 14, 2015)

@Palm::DateTime::ISA = qw( Exporter );

@Palm::DateTime::EXPORT = qw(

	datetime_to_palmtime

	dlptime_to_palmtime
	palmtime_to_dlptime

	secs_to_dlptime
	dlptime_to_secs

	palmtime_to_secs
	secs_to_palmtime

	palmtime_to_ascii
	palmtime_to_iso8601
);


#FIXME what values can wday have?

sub datetime_to_palmtime
{
	my ($datetime) = @_;

	my $palmtime = {};

	@$palmtime
	{
		'second',
		'minute',
		'hour',
		'day',
		'month',
		'year',
		'wday',

	} = unpack("nnnnnnn", $datetime);

	return $palmtime;
}


sub dlptime_to_palmtime
{
	my ($dlptime) = @_;

	my $palmtime = {};

	@$palmtime
	{
		'year',
		'month',
		'day',
		'hour',
		'minute',
		'second',

	} = unpack("nCCCCCx", $dlptime);

	return $palmtime;
}


# A future version might allow to specify only some of the fields.

sub palmtime_to_dlptime
{
	my ($palmtime) = @_;

	return pack("nCCCCCx", @$palmtime
				{
					'year',
					'month',
					'day',
					'hour',
					'minute',
					'second',
				});
}


sub secs_to_dlptime
{
	my ($secs) = @_;

	return palmtime_to_dlptime(secs_to_palmtime($secs));
}


sub dlptime_to_secs
{
	my ($dlptime) = @_;

	return palmtime_to_secs(dlptime_to_palmtime($dlptime));
}


sub palmtime_to_secs
{
	my ($palmtime) = @_;

	return POSIX::mktime(	$palmtime->{'second'},
				$palmtime->{'minute'},
				$palmtime->{'hour'},
				$palmtime->{'day'},
				$palmtime->{'month'} - 1,	# Palm used 1-12, mktime needs 0-11
				$palmtime->{'year'} - 1900,
				0,
				0,
				-1);
}


sub secs_to_palmtime
{
	my ($secs) = @_;

	my $palmtime = {};

	@$palmtime
	{
		'second',
		'minute',
		'hour',
		'day',
		'month',
		'year'
	} = localtime($secs);

	# Fix values
	$palmtime->{'year'}  += 1900;
	$palmtime->{'month'} += 1;

	return $palmtime;
}


sub palmtime_to_ascii
{
	my ($palmtime) = @_;

	return sprintf("%4d%02d%02d%02d%02d%02d",
		@$palmtime
		{
			'year',
			'month',
			'day',
			'hour',
			'minute',
			'second',
		});
}


sub palmtime_to_iso8601
{
	my ($palmtime) = @_;

	return sprintf("%4d-%02d-%02dT%02d:%02d:%02dZ",
		@$palmtime
		{
			'year',
			'month',
			'day',
			'hour',
			'minute',
			'second',
		});
}

1;

__END__

=head1 NAME

Palm::DateTime - Deal with various Palm OS date/time formats

=head1 VERSION

This document describes version 1.400 of
Palm::DateTime, released March 14, 2015
as part of Palm version 1.400.

=head1 DESCRIPTION

Palm::DateTime exports subroutines to convert between various Palm OS
date/time formats.  All subroutines are exported by default.

Data types:

 secs     - Seconds since the system epoch
 dlptime  - Palm OS DlpDateTimeType (raw)
 datetime - Palm OS DateTimeType (raw)
 palmtime - Decoded date/time (a hashref)
              KEY     VALUES
              second  0-59
              minute  0-59
              hour    0-23
              day     1-31
              month   1-12
              year    4 digits

=head1 SUBROUTINES

=head2 datetime_to_palmtime

  $palmtime = datetime_to_palmtime($datetime)

Converts Palm OS DateTimeType to a palmtime hashref.  In addition to
the usual keys, C<$palmtime> will contain a C<wday> field.


=head2 dlptime_to_palmtime

  $palmtime = dlptime_to_palmtime($dlptime)

Converts Palm OS DlpDateTimeType to a palmtime hashref.


=head2 dlptime_to_secs

  $secs = dlptime_to_secs($dlptime)

Converts a Palm OS DlpDateTimeType to epoch time.


=head2 palmtime_to_ascii

  $string = palmtime_to_secs(\%palmtime)

Converts a palmtime hashref to a C<YYYYMMDDhhmmss> string
(e.g. C<20011116200051>).
C<%palmtime> must contain all standard fields.


=head2 palmtime_to_dlptime

  $dlptime = palmtime_to_dlptime(\%palmtime)

Converts a palmtime hashref to a Palm OS DlpDateTimeType.
C<%palmtime> must contain all standard fields.


=head2 palmtime_to_iso8601

  $string = palmtime_to_iso8601(\%palmtime)

Converts a palmtime hashref to a C<YYYY-MM-DDThh:mm:ssZ> string
(e.g. C<2001-11-16T20:00:51Z>).
C<%palmtime> must contain all standard fields.
GMT timezone ("Z") is assumed.


=head2 palmtime_to_secs

  $secs = palmtime_to_secs(\%palmtime)

Converts a palmtime hashref to epoch seconds.
C<%palmtime> must contain all standard fields.


=head2 secs_to_dlptime

  $dlptime = secs_to_dlptime($secs)

Converts epoch time to a Palm OS DlpDateTimeType.


=head2 secs_to_palmtime

  $palmtime = secs_to_palmtime($secs)

Converts epoch seconds to a palmtime hashref.

=head1 CONFIGURATION AND ENVIRONMENT

Palm::DateTime requires no configuration files or environment variables.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 AUTHORS

Alessandro Zummo C<< <a.zummo AT towertech.it> >>

Currently maintained by Christopher J. Madsen C<< <perl AT cjmweb.net> >>

Please report any bugs or feature requests
to S<C<< <bug-Palm AT rt.cpan.org> >>>
or through the web interface at
L<< http://rt.cpan.org/Public/Bug/Report.html?Queue=Palm >>.

You can follow or contribute to p5-Palm's development at
L<< https://github.com/madsen/p5-Palm >>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2003 by Andrew Arensburger & Alessandro Zummo.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
