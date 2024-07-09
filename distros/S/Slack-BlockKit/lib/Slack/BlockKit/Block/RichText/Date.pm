package Slack::BlockKit::Block::RichText::Date 0.002;
# ABSTRACT: a Block Kit rich text element for a formatted date

use Moose;
use MooseX::StrictConstructor;

#pod =head1 OVERVIEW
#pod
#pod This represents a C<date> element in Block Kit, which takes a unix timestamp
#pod and displays it in a format appropriate for the reader.
#pod
#pod B<Be warned!>  The element is not documented in the Block Kit documentation,
#pod but Slack support disclosed its existence.  They said it was just missing
#pod documentation, but might it just go away?  Who can say.
#pod
#pod =cut

use v5.36.0;

#pod =attr timestamp
#pod
#pod This is the date (and time) that you want to format, which will be formatted
#pod into the reader's own time zone when displayed.  It is required, and must be a
#pod unix timestamp.  (That is: a number of seconds since 1970, as per C<<
#pod L<perlfunc/time> >>.
#pod
#pod =cut

has timestamp => (
  is  => 'ro',
  isa => 'Int', # Maybe this should be stricter, like PosInt, but eh.
  required => 1,
);

#pod =attr format
#pod
#pod This is the format string to be used formatting the timestamp.  Because the
#pod C<date> rich text element isn't documented in the Block Kit docs (currently),
#pod you'll want to find the format specification in the "L<Formatting text for app
#pod surfaces|https://api.slack.com/reference/surfaces/formatting#date-formatting>"
#pod docs.
#pod
#pod Something like this is plausible:
#pod
#pod   "{date_short_pretty}, {time}"
#pod
#pod Probably because of the C<date> element's origin in C<mrkdwn>, it has the odd
#pod property that the first character will be capitalized.  To suppress this, you
#pod can prefix your format string with C<U+200B>, the zero-width space.  For
#pod example:
#pod
#pod   "\x{200b}{date_short_pretty}, {time}"
#pod
#pod This is done, by default, in L<Slack::BlockKit::Sugar>'s C<date> function.
#pod
#pod =cut

has format => (
  is  => 'ro',
  isa => 'Str',
);

#pod =attr fallback
#pod
#pod If given, and if the client can't process the given date, this string will be
#pod displayed instead.  If you put a pre-formatted date string in this, include the
#pod time zone, because the reader will expect that it will have been localized.
#pod
#pod =cut

has fallback => (
  is  => 'ro',
  isa => 'Str',
  predicate => 'has_fallback',
);

#pod =attr url
#pod
#pod If given, the formatted date string will I<also> be a link to this URL.
#pod
#pod =cut

has url => (
  is  => 'ro',
  isa => 'Str',
  predicate => 'has_url',
);

sub as_struct ($self) {
  return {
    type => 'date',
    timestamp => 0 + $self->timestamp, # 0+ for JSON serialization's sake
    format    => "" . $self->format,
    ($self->has_fallback  ? (fallback => "" + $self->fallback)  : ()),
    ($self->has_url       ? (url      => "" . $self->url)       : ()),
  };
}

no Moose;
__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Slack::BlockKit::Block::RichText::Date - a Block Kit rich text element for a formatted date

=head1 VERSION

version 0.002

=head1 OVERVIEW

This represents a C<date> element in Block Kit, which takes a unix timestamp
and displays it in a format appropriate for the reader.

B<Be warned!>  The element is not documented in the Block Kit documentation,
but Slack support disclosed its existence.  They said it was just missing
documentation, but might it just go away?  Who can say.

=head1 PERL VERSION

This module should work on any version of perl still receiving updates from
the Perl 5 Porters.  This means it should work on any version of perl
released in the last two to three years.  (That is, if the most recently
released version is v5.40, then this module should work on both v5.40 and
v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to
lower the minimum required perl.

=head1 ATTRIBUTES

=head2 timestamp

This is the date (and time) that you want to format, which will be formatted
into the reader's own time zone when displayed.  It is required, and must be a
unix timestamp.  (That is: a number of seconds since 1970, as per C<<
L<perlfunc/time> >>.

=head2 format

This is the format string to be used formatting the timestamp.  Because the
C<date> rich text element isn't documented in the Block Kit docs (currently),
you'll want to find the format specification in the "L<Formatting text for app
surfaces|https://api.slack.com/reference/surfaces/formatting#date-formatting>"
docs.

Something like this is plausible:

  "{date_short_pretty}, {time}"

Probably because of the C<date> element's origin in C<mrkdwn>, it has the odd
property that the first character will be capitalized.  To suppress this, you
can prefix your format string with C<U+200B>, the zero-width space.  For
example:

  "\x{200b}{date_short_pretty}, {time}"

This is done, by default, in L<Slack::BlockKit::Sugar>'s C<date> function.

=head2 fallback

If given, and if the client can't process the given date, this string will be
displayed instead.  If you put a pre-formatted date string in this, include the
time zone, because the reader will expect that it will have been localized.

=head2 url

If given, the formatted date string will I<also> be a link to this URL.

=head1 AUTHOR

Ricardo SIGNES <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
