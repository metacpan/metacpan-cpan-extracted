package PGXN::Site::Locale;

use 5.10.0;
use utf8;
use parent 'Locale::Maketext';
use I18N::LangTags::Detect;
use File::Spec;
use Carp;
our $VERSION = v0.10.3;

# Allow unknown phrases to just pass-through.
our %Lexicon = (
#    _AUTO => 1,
    listcomma => ',',
    listand   => 'and',
    openquote => '“',
    shutquote => '”',
    in        => 'in',
    hometitle => 'PGXN: PostgreSQL Extension Network',
    'PostgreSQL Extension Network' => 'PostgreSQL Extension Network',
    'PGXN Gear' => 'PGXN Gear',
    'Recent' => 'Recent',
    'Recent Releases' => 'Recent Releases',
    'About' => 'About',
    'About PGXN' => 'About PGXN',
    'PGXN Users' => 'PGXN Users',
    'Recent' => 'Recent',
    'User' => 'User',
    'Users' => 'Users',
    'Recent' => 'Recent',
    'Recent Releases' => 'Recent Releases',
    'Blog' => 'Blog',
    'PGXN Blog' => 'PGXN Blog',
    'FAQ' => 'FAQ',
    'Frequently Asked Questions' => 'Frequently Asked Questions',
    'Release It' => 'Release It',
    'Release it on PGXN' => 'Release it on PGXN',
    code => 'code',
    design => 'design',
    logo => 'logo',
    'Go to [_1]' => 'Go to [_1]',
    Mirroring => 'Mirroring',
    'Mirroring PGXN' => 'Mirroring PGXN',
    Feedback => 'Feedback',
    Identity => 'Identity',
    Extensions => 'Extensions',
    Tags => 'Tags',
    Distributions => 'Distributions',
    'PGXN Search' => 'PGXN Search',
    pgxn_summary_paragraph => 'PGXN, the PostgreSQL Extension network, is a central distribution system for open-source PostgreSQL extension libraries.',
    Founders => 'Founders',
    Patrons => 'Patrons',
    Benefactors => 'Benefactors',
    Sponsors => 'Sponsors',
    Advocates => 'Advocates',
    Supporters => 'Supporters',
    Boosters => 'Boosters',
    'Donors' => 'Donors',
    'See a longer list of recent releases.' => 'See a longer list of recent releases.',
    'More Releases' => 'More Releases →',
    'Not Found' => 'Not Found',
    'Resource not found.' => 'Resource not found.',
    'Resource Not Found' => 'Resource Not Found',
    'Internal Server Error' => 'Internal Server Error',
    'Internal server error.' => 'Internal server error.',
    'Download' => 'Download',
    'Download [_1] [_2]' => 'Download [_1] [_2]',
    'Browse [_1] [_2]' => 'Browse [_1] [_2]',
    'Alas, [_1] has yet to release a distribution.' => 'Alas, [_1] has yet to release a distribution.',
    'This Release' => 'This Release',
    'Date' => 'Date',
    'Latest Stable' => 'Latest Stable',
    'Latest Testing' => 'Latest Testing',
    'Latest Unstable' => 'Latest Unstable',
    'Other Releases' => 'Other Releases',
    'Status' => 'Status',
    'stable' => 'Stable',
    'testing' => 'Testing',
    'unstable' => 'Unstable',
    'Abstract' => 'Abstract',
    'Description' => 'Description',
    'Maintainer' => 'Maintainer',
    'Maintainers' => 'Maintainers',
    'License' => 'License',
    'Resources' => 'Resources',
    'www' => 'www',
    'bugs' => 'bugs',
    'repo' => 'repo',
    'Special Files' => 'Special Files',
    'Tags' => 'Tags',
    'Other Documentation' => 'Other Documentation',
    'Released By' => 'Released By',
    'README' => 'README',
    'Documentation' => 'Documentation',
    'Nickname' => 'Nickname',
    'URL' => 'URL',
    'Email' => 'Email',
    'Twitter' => 'Twitter',
    'Follow PGXN on Twitter' => 'Follow PGXN on Twitter',
    'Browse' => 'Browse',
    'Tag: [_1]' => 'Tag: “[_1]”',
    'PGXN Search' => 'PGXN Search',
    'In the [_1] distribution' => 'In the [_1] distribution',
    'Released by [_1]' => 'Released by [_1]',
    'Search matched no documents.' => 'Search matched no documents.',
    'Previous results' => 'Previous results',
    'Next results' => 'Next results',
    '← Prev' => '← Prev',
    'Next →' => 'Next →',
    '[_1]-[_2] of [_3] found' => '[_1]-[_2] of [_3] found',
    'No Releases Yet' => 'No Releases Yet',
    'PGXN Meta Spec' => 'PGXN Meta Spec',
    'Bad Request' => 'Bad Request',
    'Bad request: Missing or invalid "[_1]" query parameter.' => 'Bad request: Missing or invalid “[_1]” query parameter.',
    '<- Select a letter' => '⬅ Select a letter',
    'Pick a letter at left' => 'Pick a letter at left',
    'No user nicknames found starting with "[_1]"' => 'No user nicknames found starting with “[_1]”',

    donors_intro => 'All the great folks who funded the inital development of PGXN will be listed in perpetuity here on the “Donors” page of PGXN.org. All donors are invited to the PGXN Launch Party at <a href="http://www.pgcon.org/2011/">PGCon</a> in May, 2011.',
);

sub accept {
    shift->get_handle( I18N::LangTags::Detect->http_accept_langs(shift) );
}

sub list {
    my ($lh, $items) = @_;
    return unless @{ $items };
    return $items->[0] if @{ $items } == 1;
    my $last = pop @{ $items };
    my $comma = $lh->maketext('listcomma');
    my $ret = join  "$comma ", @$items;
    $ret .= $comma if @{ $items } > 1;
    my $and = $lh->maketext('listand');
    return "$ret $and $last";
}

sub qlist {
    my ($lh, $items) = @_;
    return unless @{ $items };
    my $open = $lh->maketext('openquote');
    my $shut = $lh->maketext('shutquote');
    return $open . $items->[0] . $shut if @{ $items } == 1;
    my $last = pop @{ $items };
    my $comma = $lh->maketext('listcomma');
    my $ret = $open . join("$shut$comma $open", @$items) . $shut;
    $ret .= $comma if @{ $items } > 1;
    my $and = $lh->maketext('listand');
    return "$ret $and $open$last$shut";
}

my %PATHS_FOR;

sub DESTROY {
    delete $PATHS_FOR{ ref shift };
}

sub from_file {
    my ($self, $path) = (shift, shift);
    my $class = ref $self;
    my $file = $PATHS_FOR{$class}{$path} ||= _find_file($class, $path);
    open my $fh, '<:utf8', $file or die "Cannot open $file: $!\n";
    my $value = do { local $/; $self->_compile(<$fh>); };
    return ref $value eq 'CODE' ? $value->($self, @_) : ${ $value };
}

sub _find_file {
    my $class = shift;
    my @path = split m{/}, shift;
    (my $dir = __FILE__) =~ s{[.]pm$}{};
    no strict 'refs';
    foreach my $super ($class, @{$class . '::ISA'}, __PACKAGE__ . '::en') {
        my $file = File::Spec->catfile($dir, $super->language_tag, @path);
        return $file if -e $file;
    }
    croak "No file found for path " . join('/', @path);
}

1;

=encoding utf8

=head1 Name

PGXN::Site::Locale - Localization for PGXN::Site

=head1 Synopsis

  use PGXN::Site::Locale;
  my $mt = PGXN::Site::Locale->accept($env->{HTTP_ACCEPT_LANGUAGE});

=head1 Description

This class provides localization support for PGXN::Site. Each locale must
create a subclass named for the locale and put its translations in the
C<%Lexicon> hash. It is further designed to support easy creation of
a handle from an HTTP_ACCEPT_LANGUAGE header.

=head1 Interface

The interface inherits from L<Locale::Maketext> and adds the following
method.

=head2 Constructor Methods

=head3 C<accept>

  my $mt = PGXN::Site::Locale->accept($env->{HTTP_ACCEPT_LANGUAGE});

Returns a PGXN::Site::Locale handle appropriate for the specified
argument, which must take the form of the HTTP_ACCEPT_LANGUAGE string
typically created in web server environments and specified in L<RFC
3282|http://tools.ietf.org/html/rfc3282>. The parsing of this header is
handled by L<I18N::LangTags::Detect>.

=head2 Instance Methods

=head3 C<list>

  # "Missing these keys: foo, bar, and baz"
  say $mt->maketext(
      'Missing these keys: [list,_1])'
      [qw(foo bar baz)],
  );

Formats a list of items. The list of items to be formatted should be passed as
an array reference. If there is only one item, it will be returned. If there
are two, they will be joined with " and ". If there are more, there will be a
comma-separated list with the final item joined on ", and ".

Note that locales can control the localization of the comma and "and" via the
C<listcomma> and C<listand> entries in their C<%Lexicon>s.

=head3 C<qlist>

  # "Missing these keys: “foo”, “bar”, and “baz”
  say $mt->maketext(
      'Missing these keys: [qlist,_1]'
      [qw(foo bar baz)],
  );

Like C<list()> but quotes each item in the list. Locales can specify the
quotation characters to be used via the C<openquote> and C<shutquote> entries
in their C<%Lexicon>s.

=head3 C<from_file>

  my $text = $mt->from_file('foo/bar.html');
  my $msg  = $mt->from_file('feedback.html', 'pgxn@example.com');

Returns the contents of a localized file. The file argument should be
specified with Unix semantics, regardless of operating system. Whereas
subclasses contain short strings that need translating, the files can contain
complete documents. As with C<maketext()>, the support the full range variable
substitution, such as C<[_1]> and friends.

If a file doesn't exist for the current language, C<from_file()> will fall
back on the same file path for any of its parent classes. If none has the
file, it will fall back on the English file.

Localized files are maintained in L<Text::MultiMarkdown> format by translators
and converted to HTML at build time. The live in a subdirectory named for the
last part of a subclass's package name. For example, the
L<PGXN::Site::Locale::fr> class lives in F<PGXN/Site/Locale/fr.pm>. Localized
files will live in F<PGXN/Site/Locale/fr/>. So for the argument
C<feedback.html>, the localized file will be
F<PGXN/Site/Locale/fr/foo/bar.mmd>, and the HTML file (created at build time)
will be F<PGXN/Site/Locale/fr/foo/bar.html>.

=head1 Author

David E. Wheeler <david.wheeler@pgexperts.com>

=head1 Copyright and License

Copyright (c) 2010-2013 David E. Wheeler.

This module is free software; you can redistribute it and/or modify it under
the L<PostgreSQL License|http://www.opensource.org/licenses/postgresql>.

Permission to use, copy, modify, and distribute this software and its
documentation for any purpose, without fee, and without a written agreement is
hereby granted, provided that the above copyright notice and this paragraph
and the following two paragraphs appear in all copies.

In no event shall David E. Wheeler be liable to any party for direct,
indirect, special, incidental, or consequential damages, including lost
profits, arising out of the use of this software and its documentation, even
if David E. Wheeler has been advised of the possibility of such damage.

David E. Wheeler specifically disclaims any warranties, including, but not
limited to, the implied warranties of merchantability and fitness for a
particular purpose. The software provided hereunder is on an "as is" basis,
and David E. Wheeler has no obligations to provide maintenance, support,
updates, enhancements, or modifications.

=cut
