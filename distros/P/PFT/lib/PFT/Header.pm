# Copyright 2014-2016 - Giovanni Simoni
#
# This file is part of PFT.
#
# PFT is free software: you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your
# option) any later version.
#
# PFT is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with PFT.  If not, see <http://www.gnu.org/licenses/>.
#
package PFT::Header v1.3.0;

=encoding utf8

=head1 NAME

PFT::Header - Header for PFT content textfiles

=head1 SYNOPSIS

    use PFT::Header;

    my $hdr = PFT::Header->new(
        title => $title,        # mandatory (conditions apply)
        slug => $slug,          # optional short identifier
        date => $date,          # optional (conditions apply) PFT::Date
        author => $author,      # optional
        tags => $tags,          # list of decoded strins, defaults to []
        opts => $opts,          # ignored by internals, defaults to {}
    );

    my $hdr = PFT::Header->load(\*STDIN);

    my $hdr = PFT::Header->load('/path/to/file');

=head1 DESCRIPTION

A header is a chunk of meta-information describing content properties.

It is used in a PFT::Tree::Content structure as index for retrieving the
content on the filesystem. Every textual content (i.e.
PFT::Content::Entry) stores a textual representation of an header in the
beginning of the file.

=head2 Structure

Each content has a I<title>, an optional I<author>, an optional list of
I<tags> in form of strings, an optional hash I<opts> containing other
options.

=head2 Textual representation

The textual representation of a header starts with a valid YAML document
(including the leading '---' line and ends with another '---' line).

=head2 Construction

The header can be constructed in three ways, corresponding to the three
forms in the B<SYNOPSIS>.

The first form is constructed in code. The I<title> field is mandatory
unless there is a I<date> field, and the date represents a month (i.e.
lacks the I<day> field). This property is enforced by the constructor.

The second and third forms are equivalent, and they differ in the source
from which a header is loaded (a stream or a file path, respectively).

=cut

use utf8;
use v5.16;
use strict;
use warnings;

use Carp;
use Encode::Locale;
use Encode;
use YAML::Tiny;

use PFT::Date;

# Restrictions on header fields are handled by the following function,
# as they are not just booleans.
sub _params_check {
    my $params = shift;

    if (exists $params->{date} and defined(my $d = $params->{date})) {
        $d->isa('PFT::Date')
            or confess 'date parameter must be PFT::Date';

        if ($d->complete) {
            $params->{title}
                or croak 'Title is mandatory headers having complete date';
        } elsif (!defined $d->y or !defined $d->m) {
            croak 'Year and month are mandatory for headers with date';
        }
    } else {
        $params->{title}
            or croak 'Title is mandatory for headers not having dates';
    }
};

# Keys are recognized options. Values are arrays:
# - The default option;
# - The normalization callback, or undef if the normalization is the
#   identity function.
my %OPTS_RECIPE = (
    hide        => [0,      sub { 0 + shift }],
    template    => [undef,  undef            ],
);

sub _opts_default {
    my %out;
    while (my($k, $vs) = each %OPTS_RECIPE) {
        $out{$k} = $vs->[0]
    }
    \%out
}

sub _opts_normalize {
    my $opts = shift;
    foreach (keys %$opts) {
        if (defined(my $cb = $OPTS_RECIPE{$_}->[1])) {
            $opts->{$_} = $cb->($opts->{$_})
        }
    }
    $opts
}

sub new {
    my $cls = shift;
    my %params = @_;

    _params_check(\%params);
    bless {
        title => $params{title},
        author => $params{author},
        date => $params{date},
        tags => $params{tags} || [],
        opts => $params{opts} || _opts_default(),
        slug => do {
            my $given = $params{slug} || $params{title};
            defined $given ? slugify($given) : undef
        },
    }, $cls;
}

sub load {
    my($cls, $from) = @_;

    my $fname;
    if (my $type = ref $from) {
        $fname = "?? $type ??";
        unless ($type eq 'GLOB' || $type eq 'IO::File') {
            confess "Only supporting GLOB and IO::File. Got $type";
        }
    } else {
        $fname = $from;
        $from = IO::File->new($from) or confess "Cannot open $from";
    }
    binmode $from, ':encoding(locale)' or confess "Binmode: $!";

    # Header starts with a valid YAML document (including the leading
    # /^---$/ string) and ends with another /^---$/ string.
    my $text = <$from>;
    local $_;
    while (<$from>) {
        last if ($_ =~ /^---$/);
        $text .= $_;
    }

    my $hdr = eval { YAML::Tiny::Load($text || '') };
    $hdr or confess "File $fname has corrupt header";

    my $date;
    $hdr->{Date} and $date = eval {
        PFT::Date->from_string($hdr->{Date})
    };
    croak $@ =~ s/ at .*$//rs if $@;
    delete $hdr->{Date};

    my $title = delete $hdr->{Title};
    my $self = {
        title => $title,
        slug => do {
            my $given = delete $hdr->{Slug} || $title;
            defined $given ? slugify($given) : undef
        },
        author => delete $hdr->{Author},
        tags => [ do {
            my $tags = delete $hdr->{Tags};
            ref $tags eq 'ARRAY' ? @$tags
                : defined $tags ? $tags
                : ()
        }],
        date => $date,
        opts => _opts_normalize(delete $hdr->{Options}),
    };
    _params_check($self);

    foreach (keys %$hdr) {
        warn 'Unexpected key in header: ', $_;
    }
    foreach (keys %{$self->{opts}}) {
        warn 'Unexpected key in header: opts.', $_
            unless exists $OPTS_RECIPE{$_}
    }

    bless $self, $cls;
}

=head2 Functions

The following functions are not associated with an instance. Call them as
C<PFT::Header::function(...)>

=over

=item slugify

Given a string, construct a I<slug>, that is a simplified version of such
string.

(TODO: better describe it, also w.r.t. Unicode)

=cut

sub slugify {
    my $out = shift;
    confess 'Slugify of nothing?' unless $out;

    $out =~ s/[\W_]/-/g;
    $out =~ s/-+$//;
    $out =~ s/^-+//;
    $out =~ s/--+/-/g;
    lc $out
};

=back

=head2 Properties

    $hdr->title
    $hdr->author
    $hdr->template
    $hdr->tags
    $hdr->date
    $hdr->opts
    $hdr->slug
    $hdr->tags_slug

=over

=item title

Returns the title of the content.

Outputs a in decoded string.

=cut

sub title { shift->{title} }

=item author

Returns the author of the content, or undef if there is no author.

Outputs a in decoded string.

=cut

sub author { shift->{author} }

=item tags

A list of tags declared by the header.

The tags are in a normal (i.e. not slugified) form. For a slugified
version use the C<tags_slug> method.

=cut

sub tags { wantarray ? @{shift->{tags}} : shift->{tags} }

=item date

The date declared by the heade, as PFT::Date object.

=cut

sub date { shift->{date} }

=item opts

A list of options for this content.

=cut

sub opts { shift->{opts} || {} }

=item slug

A slug of the title.

=cut

sub slug {
    my $self = shift;
    $self->{slug} || $self->{title} && slugify($self->{title}) || undef
}

=item tags_slug

A list of tags as for the C<tags> method, but in slugified form.

=cut

sub tags_slug {
    map slugify($_) => @{shift->tags || []}
}

=back

=head2 Methods

=over

=item set_date

Setter for date. The parameter must be a PFT::Date object.

=cut

sub set_date {
    my $self = shift;
    my $date = pop;

    $date->isa('PFT::Date') or confess 'Must be PFT::Date';
    $self->{date} = $date;
}

=item dump

Dump the header on a file. A GLOB or IO::File is expected as argument.

=cut

sub dump {
    my $self = shift;
    my $to = shift;

    my $type = ref $to;
    if ($type ne 'GLOB' && $type ne 'IO::File') {
        confess "Only supporting GLOB and IO::File. Got ",
                $type ? $type : 'Scalar'
    }
    my $tags = $self->tags;
    binmode $to, ':encoding(locale)' or confess "Cannot binmode: $!";
    print $to YAML::Tiny::Dump({
        Title => $self->title,
        Slug => $self->slug,
        Author => $self->author,
        Tags => @$tags ? $tags : undef,
        Date => $self->date ? $self->date->repr('-') : undef,
        Options => _opts_normalize($self->opts),
    }), "---\n";
}

=back

=cut

1;
