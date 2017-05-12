package MooseX::Types::DateTime::ButMaintained;
use strict;
use warnings;

our $VERSION = "0.16";

use Moose 0.41 ();
use DateTime ();
use DateTime::Locale ();
use DateTime::TimeZone ();
use Olson::Abbreviations 0.03 qw();

use MooseX::Types::Moose 0.30 qw/Num HashRef Str/;

use MooseX::Types 0.30 -declare => [qw( DateTime Duration TimeZone Locale Now )];

use namespace::autoclean;

class_type "DateTime";
class_type "DateTime::Duration";
class_type "DateTime::TimeZone";
class_type "DateTime::Locale::root" => { name => "DateTime::Locale" };

subtype DateTime, as 'DateTime';
subtype Duration, as 'DateTime::Duration';
subtype TimeZone, as 'DateTime::TimeZone';
subtype Locale,   as 'DateTime::Locale';

subtype( Now, as Str, where { $_ eq 'now' },
	( $Moose::VERSION >= 2.0100
		? Moose::Util::TypeConstraints::inline_as {
			'no warnings "uninitialized";'.
			'!ref(' . $_[1] . ') and '. $_[1] .' eq "now"';
		}
		: Moose::Util::TypeConstraints::optimize_as {
			no warnings 'uninitialized';
			!ref($_[0]) and $_[0] eq 'now';
		}
	)
);

our %coercions = (
	DateTime => [
		from Num, via { 'DateTime'->from_epoch( epoch => $_ ) }
		, from HashRef, via { 'DateTime'->new( %$_ ) }
		, from Now, via { 'DateTime'->now }
	]

	, "DateTime::Duration" => [
		from Num, via { DateTime::Duration->new( seconds => $_ ) }
		, from HashRef, via { DateTime::Duration->new( %$_ ) }
	]

	, "DateTime::TimeZone" => [
		from Str, via {
			# No abbreviation - assumed if we don't have a '/'
			if ( m,/|floating|local, ) {
				return DateTime::TimeZone->new( name => $_ );
			}
			# Abbreviation - assumed if we do have a '/'
			# returns a DateTime::TimeZone::OffsetOnly
			else {
				my $offset = Olson::Abbreviations->new({ tz_abbreviation => $_ })->get_offset;
				return DateTime::TimeZone->new( name => $offset );
			}
		}
	]

	, "DateTime::Locale" => [
		from Moose::Util::TypeConstraints::find_or_create_isa_type_constraint("Locale::Maketext")
			, via { DateTime::Locale->load($_->language_tag) }
		, from Str, via { DateTime::Locale->load($_) }
	]
);

for my $type ( "DateTime", DateTime ) {
	coerce $type => @{ $coercions{DateTime} };
}

for my $type ( "DateTime::Duration", Duration ) {
	coerce $type => @{ $coercions{"DateTime::Duration"} };
}

for my $type ( "DateTime::TimeZone", TimeZone ) {
	coerce $type => @{ $coercions{"DateTime::TimeZone"} };
}

for my $type ( "DateTime::Locale", Locale ) {
	coerce $type => @{ $coercions{"DateTime::Locale"} };
}

1;

__END__

=head1 NAME

MooseX::Types::DateTime::ButMaintained - L<DateTime> related constraints and coercions for Moose

=head1 SYNOPSIS

Export Example:

	use MooseX::Types::DateTime::ButMaintained qw(TimeZone);
	has time_zone => (
			isa  => TimeZone
			, is => "rw"
			, coerce => 1
	);
	Class->new( time_zone => "Africa/Timbuktu" );
	Class->new( time_zone => "CEST" );

Namespaced Example:

	use MooseX::Types::DateTime::ButMaintained;
	has time_zone => (
		isa  => 'DateTime::TimeZone'
		, is => "rw"
		, coerce => 1
	);
	Class->new( time_zone => "Africa/Timbuktu" );

=head1 CONSTRAINTS

=over 4

=item L<DateTime>

A class type for L<DateTime>.

=over 4

=item from C<Num>

Uses L<DateTime/from_epoch>. Floating values will be used for subsecond percision, see L<DateTime> for details.

=item from C<HashRef>

Calls L<DateTime/new> with the hash entries as arguments.

=back

=item L<Duration>

A class type for L<DateTime::Duration>

=over 4

=item from C<Num>

Uses L<DateTime::Duration/new> and passes the number as the C<seconds> argument.

Note that due to leap seconds, DST changes etc this may not do what you expect.  For instance passing in C<86400> is not always equivalent to one day, although there are that many seconds in a day. See L<DateTime/"How Date Math is Done"> for more details.

=item from C<HashRef>

Calls L<DateTime::Duration/new> with the hash entries as arguments.

=back

=item L<DateTime::Locale>

A class type for L<DateTime::Locale::root> with the name L<DateTime::Locale>.

=over 4

=item from C<Str>

The string is treated as a language tag (e.g. C<en> or C<he_IL>) and given to L<DateTime::Locale/load>.

=item from L<Locale::Maktext>

The C<Locale::Maketext/language_tag> attribute will be used with L<DateTime::Locale/load>.

=back

=item L<DateTime::TimeZone>

A class type for L<DateTime::TimeZone>, this now as of 0.05 coerces from non-globally ambigious Olson abbreviations, using L<Olson::Abbreviations>. This won't work for abbreviations like "EST" which are only unambigious if you know the locale. It will coerce from abbreviations like "CEST" though.

=over 4

=item from C<Str>

Treated as a time zone name or offset. See L<DateTime::TimeZone/USAGE> for more details on the allowed values.

Delegates to L<DateTime::TimeZone/new> with the string as the C<name> argument.

=back

=back

=head1 SEE ALSO

L<MooseX::Types::DateTimeX>

L<DateTime>

=head1 AUTHOR

=head2 Modern

Evan Carroll E<lt>me+cpan@evancarroll.comE<gt>

=head2 Yesteryear

Yuval Kogman E<lt>nothingmuch@woobling.orgE<gt>

John Napiorkowski E<lt>jjn1056 at yahoo.comE<gt>

=head1 DESCRIPTION

This module packages several L<Moose::Util::TypeConstraints> with coercions, designed to work with the L<DateTime> suite of objects.

This module started as a fork of L<MooseX::Types::DateTime>. This history and explaination is as follows:
In Janurary 2009, I began a project to bring DateTime::Format::* stuff up to date with Moose. I created a framework that would greatly eliminate redundant code named L<DateTimeX::Format>. This project's adoption was slowed by then (and still currently) bundeled B<package> MooseX::Types::DateTime. MooseX::Types::DateTime was a badly packaged extention of two modules the self-titled MooseX::Types::DateTime, and another random module MooseX::Types::DateTimeX. In Februrary of the same year, I repackaged the module L<MooseX::Types::DateTimeX> with the authors blessing into a new package, for the purpose of removing its dependenices, namely L<Date::Manip>, from MooseX::Types::DateTime.

Unfortunately, this just added confusion. Now, as of the time of writing L<MooseX::Types::DateTimeX> is available as a package, and it is available as a module which will be installed by L<MooseX::Types::DateTime>. The benefit of removing the dependency on L<MooseX::Types::DateTime> was never realized and the patch that updates the dependencies, and the build system remains in rt still as of writing.

This module is just the L<MooseX::Types::DateTime> without the requirement on L<DateTimeX::Easy> (which requires L<DateTime::Manip>). As of 0.05 this module supports globally unique Olson abbreviations, and dies when they are not globally unique.

=head1 COPYRIGHT

	Copyright (c) 2008 Yuval Kogman. All rights reserved
	This program is free software; you can redistribute
	it and/or modify it under the same terms as Perl itself.

	Modifications (c) 2009 Evan Carroll. All rights reserved
	This program is free software; you can redistribute
	it and/or modify it under the same terms as Perl itself.

=cut
