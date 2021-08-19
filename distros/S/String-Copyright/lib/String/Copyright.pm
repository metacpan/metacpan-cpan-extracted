use 5.008001;
use strict;
use warnings;
use utf8;
use re (qw/eval/);

package String::Copyright;

=encoding UTF-8

=head1 NAME

String::Copyright - Representation of text-based copyright statements

=head1 VERSION

Version 0.003008

=cut

our $VERSION = '0.003008';

# Dependencies
use parent 'Exporter::Tiny';
use Carp ();
use Number::Range;

our @EXPORT = qw/copyright/;

use constant {
	PLAINTEXT => 0,
	BLOCKS    => 1,
	FORMAT    => 2,
};

use overload (
	q{""}    => '_compose',
	fallback => 1,
);

=head1 SYNOPSIS

    use String::Copyright;

    my $copyright = copyright(<<'END');
    copr. © 1999,2000 Foo Barbaz <fb@acme.corp> and Acme Corp.
    Copyright (c) 2001,2004 Foo (work address) <foo@zorg.corp>
    Copyright 2003, Foo B. and friends
    © 2000, 2002 Foo Barbaz <foo@bar.baz>
    END

    print $copyright;

    # Copyright 1999-2000 Foo Barbaz <fb@acme.com> and Acme Corp.
    # Copyright 2000, 2002 Foo Barbaz and Acme Corp.
    # Copyright 2001, 2004 Foo (work address) <foo@zorg.org>
    # Copyright 2003 Foo B. and friends

=head1 DESCRIPTION

L<String::Copyright> Parses common styles of copyright statements
and serializes in normalized format.

=head1 OPTIONS

Options can be set as an argument to the 'use' statement.

=head2 threshold, threshold_before, threshold_after

    use String::Copyright { threshold_after => 5 };

Stop parsing after this many lines whithout copyright information,
before or after having found any copyright information at all.
C<threshold> sets both C<threshold_before> and C<threshold_after>.

By default unset: All lines are parsed.

=head2 format( \&sub )

    use String::Copyright { format => \&GNU_style } };

    sub GNU_style {
        my ( $years, $owners ) = @_;

        return 'Copyright (C) ' . join '  ', $years || '', $owners || '';
    }

=head1 FUNCTIONS

Exports one function: C<copyright>.
This module uses L<Exporter::Tiny> to export functions,
which allows for flexible import options;
see the L<Exporter::Tiny> documentation for details.

=cut

# OR'ed strings have regular variable name and are already grouped
# AND'ed strings have name ending in underscore: must be grouped if repeated
my $blank           = '[ \t]';
my $blank_or_break_ = "$blank*\\n?$blank*";
my $sign = '(?i:copyright(?:-holders?)?\b|copr\.|[©⒞Ⓒⓒ🄒🄫🅒])';
my $pseudo_sign_ = '[({][Cc][})]';
my $broken_sign_ = "\\?$blank*";
my $nonsign      = "(?:no |_)copyright|copyright-[^h]";

my $year_ = '\b[0-9]{4}\b';
my $comma = "(?:$blank*,$blank_or_break_|$blank_or_break_,?$blank*)";
my $dash_ = "$blank*[-˗‐‑‒–—―⁃−﹣－](?:$blank_or_break_)*";
my $owner_intro_  = "\\bby$blank_or_break_";
my $owner_prefix  = '[(*<@\[{]';
my $owner_initial = '[^\s!"#$%&\'()*+,./:;<=>?@[\\\\\]^_`{|}~]';

# this should cause *no* false positives, and stop-chars therefore
# exclude e.g. email address building blocks; tested against the code
# corpus at https://codesearch.debian.net/ (tricky: its RE2 engine lacks
# support for negative groups) using searches like these:
# (?i)copyright (?:(?:claim|holder|info|information|notice|owner|ownership|statement|string)s?|in|is|to)@\w
# (?i)copyright (?:(?:claim|holder|info|information|notice|owner|ownership|statement|string)s?|in|is|to)@\b[-_@]
# (?im)copyright (?:(?:claim|holder|info|information|notice|owner|ownership|statement|string)s?|in|is|to)[^ $]
my $chatter_copyright
	= '(?i:assigned|transfer(?:red)?|(?:block|claim|holder|info|information|law|notice|owner|ownership|statement|string|tag)s?|and|appl(?:y|ie[ds])|at|eq|generated|in|is|on|or|to)';
my $the_notname
	= '(?i:concrete|fault|first|immediately|least|min\/max|one|outer|previous|ratio|sum|user)';
my $the_sentence_
	= "(?:\\w+$blank+){1,10}(?i:are|can(?:not)?|in|is|must|was)";
my $chatter_pseudosign_
	= "(?:the$blank+(?:$the_notname|$the_sentence_)|there)\\b";
my $chatter
	= "(?im:$nonsign|copyright$blank_or_break_$chatter_copyright(?:$|@\\W|[^a-zA-Z0-9@_-])|$blank*$pseudo_sign_(?:$blank_or_break_)+$chatter_pseudosign_)";

my $signs
	= "(?m:(?:$sign|(?:^|$blank)$pseudo_sign_):?(?:$blank*(?:$sign|$pseudo_sign_))*)";
my $yearspan_ = "$year_(?:$dash_$year_)?";
my $years_    = qr/$yearspan_(?:$comma$yearspan_)*/;
my $owners_   = "$owner_prefix*$owner_initial\\S*(?:$blank*\\S+)*";

my $dash_re          = qr/$dash_/;
my $owner_intro_A_re = qr/^$owner_intro_/;
my $boilerplate_X_re = qr/(?i)${comma}All$blank+Rights$blank+Reserved[.!]?.*/;
my $signs_and_more_re
	= qr/$chatter.*|$signs(?::$blank_or_break_|$comma)(?:$broken_sign_)?($years_?$comma?(?:$owner_intro_)?(?:$owners_)?)|(?:\n|\z)/;

sub _generate_copyright
{
	my ( $class, $name, $args, $globals ) = @_;

	return sub {
		my $copyright = shift;

		Carp::croak("String::Copyright strings require defined parts")
			unless 1 + @_ == grep {defined} $copyright, @_;

	   # String::Copyright objects are effectively immutable and can be reused
		if ( !@_ && ref($copyright) eq __PACKAGE__ ) {
			return $copyright;
		}

		# stringify objects
		$copyright = "$copyright";

		# TODO: also parse @_ - but each separately!
		my @block;
		my $skipped = 0;
		while ( $copyright =~ /$signs_and_more_re/g ) {
			my $owners = $1;
			if ( $globals->{threshold_before} || $globals->{threshold} ) {
				last
					if (!@block
					and !length $owners
					and ++$skipped >= ( $globals->{threshold_before}
							|| $globals->{threshold} ) );
			}
			if ( $globals->{threshold_after} || $globals->{threshold} ) {

				# "after" detects end of _current_ line so is skewed by one
				last
					if (@block
					and !length $owners
					and ++$skipped >= 1
					+ ( $globals->{threshold_after} || $globals->{threshold} )
					);
			}
			next if ( !length $owners );
			$skipped = 0;

			my $years;
			my @span = $owners =~ /\G($yearspan_)(?:$comma|\Z)/gm;
			if (@span) {
				$owners = substr( $owners, $+[0] );

				# deduplicate
				my %range;
				for (@span) {
					my ( $y1, $y2 ) = split /$dash_re/;
					if ( !$y2 ) {
						$range{$y1} = undef;
					}
					elsif ( $y1 > $y2 ) {
						@range{ $y2 .. $y1 } = undef;
					}
					else {
						@range{ $y1 .. $y2 } = undef;
					}
				}

				# normalize
				my $range = Number::Range->new( keys %range );
				$years = $range->range;
				$years =~ s/,/, /g;
				$years =~ s/\.\./-/g;
			}
			if ($owners) {
				$owners =~ s/$owner_intro_A_re//g;
				$owners =~ s/\s{2,}/ /g;
				$owners =~ s/$owner_intro_A_re//g;
				$owners =~ s/$boilerplate_X_re//g;
			}

# split owner into owner_id and owner

			push @block, [ $years || undef, $owners || undef ];
		}

# TODO: save $skipped_lines to indicate how dirty parsing was

		my $ext_format = $globals->{format};
		my $format
			= $globals->{format}
			? sub { $ext_format->( $_->[0], $_->[1] ) }
			: sub { join ' ', '©', $_->[0] || (), $_->[1] || () };

		bless [ $copyright, \@block, $format ], __PACKAGE__;
	}
}

sub new
{
	my ( $self, @data ) = @_;
	Carp::croak("String::Copyright require defined, positive-length parts")
		unless 1 + @_ == grep { defined && length } @data;

	# String::Copyright objects are simply stripped of their string part
	if ( !@_ && ref($self) eq __PACKAGE__ ) {
		return bless [ undef, $data[1] ], __PACKAGE__;
	}

	# FIXME: properly validate data
	Carp::croak("String::Copyright blocks must be an array of strings")
		unless @_ == grep { ref eq 'ARRAY' } @data;

	bless [ undef, \@data ], __PACKAGE__;
}

sub _compose
{
	my $format = $_[0]->[FORMAT];
	join "\n", map {&$format} @{ $_[0]->[BLOCKS] };
}

sub is_normalized { !defined $_[0]->[PLAINTEXT] }

=head1 SEE ALSO

=over 4

=item *

L<Encode>

=item *

L<Exporter::Tiny>

=back

=head1 BUGS/CAVEATS/etc

L<String::Copyright> operates on strings, not bytes.
Data encoded as UTF-8, Latin1 or other formats
need to be decoded to strings before use.

Only ASCII characters and B<©> (copyright sign) are directly processed.

If copyright sign is mis-detected
or accents or multi-byte characters display wrong,
then most likely the data was not decoded into a string.

If ranges or lists of years are not tidied,
then maybe it contained non-ASCII whitespace or digits.

=head1 AUTHOR

Jonas Smedegaard C<< <dr@jones.dk> >>

=head1 COPYRIGHT AND LICENSE

Derived from L<App::Licensecheck> originally part of the KDE SDK,
originally introduced by Stefan Westerfeld C<< <stefan@space.twc.de> >>;
and on the script licensecheck2dep5 part of Debian CDBS tool,
written by Jonas Smedegaard.

  Copyright © 2007, 2008 Adam D. Barratt

  Copyright © 2005-2012, 2016 Jonas Smedegaard

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any
later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License along
with this program. If not, see <https://www.gnu.org/licenses/>.

=cut

1;
