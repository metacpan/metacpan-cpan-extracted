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
package PFT::Content v1.3.0;

=encoding utf8

=head1 NAME

PFT::Content - Filesytem tree mapping content

=head1 SYNOPSIS

    PFT::Content->new($basedir);
    PFT::Content->new($basedir, {create => 1});

=head1 DESCRIPTION

The structure is the following:

    content
    ├── attachments
    ├── blog
    ├── pages
    ├── pics
    └── tags

=cut

use strict;
use warnings;
use utf8;
use v5.16;

use Carp;
use Encode::Locale;
use Encode;

use File::Basename qw/dirname basename/;
use File::Path qw/make_path/;
use File::Spec;

use PFT::Content::Attachment;
use PFT::Content::Blog;
use PFT::Content::Month;
use PFT::Content::Page;
use PFT::Content::Picture;
use PFT::Content::Tag;
use PFT::Date;
use PFT::Header;
use PFT::Util;

use constant {
    path_sep => File::Spec->catfile('',''),  # portable '/'
};

sub new {
    my $cls = shift;
    my $base = shift;
    my $opts = shift;

    my $self = bless { base => $base }, $cls;
    $opts->{create} and $self->_create();
    $self;
}

sub _create {
    my $self = shift;
    make_path(map $self->$_ => qw/
        dir_blog
        dir_pages
        dir_tags
        dir_pics
        dir_attachments
    /), {
        #verbose => 1,
        mode => 0711,
    }
}

=head2 Properties

Quick accessors for directories

    $tree->dir_root
    $tree->dir_blog
    $tree->dir_pages
    $tree->dir_tags
    $tree->dir_pics
    $tree->dir_attachments

Non-existing directories are created by the constructor if the
C<{create =E<gt> 1}> option is passed as last constructor argument.

=cut

sub dir_root { shift->{base} }
sub dir_blog { File::Spec->catdir(shift->{base}, 'blog') }
sub dir_pages { File::Spec->catdir(shift->{base}, 'pages') }
sub dir_tags { File::Spec->catdir(shift->{base}, 'tags') }
sub dir_pics { File::Spec->catdir(shift->{base}, 'pics') }
sub dir_attachments { File::Spec->catdir(shift->{base}, 'attachments') }

=head2 Methods

=over

=item new_entry

Create and return a page. A header is required as argument.

If the page does not exist it gets created according to the header. If the
header contains a date, the page is considered to be a I<blog entry> (and
positioned as such). If the data is missing the I<day> information, the
entry is a I<month entry>.

=cut

sub new_entry {
    my $self = shift;
    my $hdr = shift;

    my $p = $self->entry($hdr);
    $hdr->dump($p->open('w')) unless $p->exists;
    return $p
}

=item entry

Similar to C<new_entry>, but does not create a content file if it
doesn't exist already.

=cut

sub entry {
    my $self = shift;
    my $hdr = shift;
    confess "Not a header: $hdr" unless $hdr->isa('PFT::Header');

    my $params = {
        tree => $self,
        path => $self->hdr_to_path($hdr),
        name => $hdr->title,
    };

    my $d = $hdr->date;
    defined $d
        ? $d->complete
            ? PFT::Content::Blog->new($params)
            : PFT::Content::Month->new($params)
        : PFT::Content::Page->new($params)
}

=item hdr_to_path

Given a PFT::Header object, returns the path of a page or blog page within
the tree.

Note: this function does not work properly if you are seeking for a
I<tag>. I<Tags> are a different beast, since they have the same header as
a page, but they belong to a different place.

=cut

sub hdr_to_path {
    my $self = shift;
    my $hdr = shift;
    confess 'Not a header' unless $hdr->isa('PFT::Header');

    if (defined(my $d = $hdr->date)) {
        my($basedir, $fname);

        defined $d->y && defined $d->m
            or confess 'Year and month are required';

        my $ym = sprintf('%04d-%02d', $d->y, $d->m);
        if (defined $d->d) {
            $basedir = File::Spec->catdir($self->dir_blog, $ym);
            $fname = sprintf('%02d-%s', $d->d, $hdr->slug);
        } else {
            $basedir = $self->dir_blog;
            $fname = $ym . '.month';
        }

        File::Spec->catfile($basedir, $fname)
    } else {
        File::Spec->catfile($self->dir_pages, $hdr->slug)
    }
}

=item new_tag

Create and return a I<tag page>. A header is required as argument. If the
tag page does not exist it gets created according to the header.

=cut

sub new_tag {
    my $self = shift;
    my $hdr = shift;

    my $p = $self->tag($hdr);
    $hdr->dump($p->open('w')) unless $p->exists;
    return $p;
}

=item tag

Similar to C<new_tag>, but does not create the content file if it doesn't
exist already.

=cut

sub tag {
    my $self = shift;
    my $hdr = shift;

    confess "Not a header: $hdr" unless $hdr->isa('PFT::Header');
    PFT::Content::Tag->new({
        tree => $self,
        path => File::Spec->catfile($self->dir_tags, $hdr->slug),
        name => $hdr->title,
    })
}

sub _text_ls {
    my $self = shift;

    my @out;
    for my $path (PFT::Util::locale_glob @_) {
        my $hdr = eval { PFT::Header->load($path) }
            or confess "Loading header of $path: " . $@ =~ s/ at .*$//rs;

        push @out, {
            tree => $self,
            path => $path,
            name => $hdr->title,
        };
    }
    @out
}

=item blog_ls

List all blog entries (days and months).

=cut

sub blog_ls {
    my $self = shift;
    map(
        PFT::Content::Blog->new($_),
        $self->_text_ls(File::Spec->catfile($self->dir_blog, '*', '*'))
    ),
    map(
        PFT::Content::Month->new($_),
        $self->_text_ls(File::Spec->catfile($self->dir_blog, '*.month'))
    )
}

=item pages_ls

List all pages (not tags pages)

=cut

sub pages_ls {
    my $self = shift;
    map PFT::Content::Page->new($_),
        $self->_text_ls(File::Spec->catfile($self->dir_pages, '*'))
}

=item tags_ls

List all tag pages (not regular pages)

=cut

sub tags_ls {
    my $self = shift;
    map PFT::Content::Tag->new($_),
        $self->_text_ls(File::Spec->catfile($self->dir_tags, '*'))
}

=item entry_ls

List all entries (pages + blog + tags)

=cut

sub entry_ls {
    my $self = shift;
    $self->pages_ls,
    $self->blog_ls,
    $self->tags_ls,
}

sub _blob {
    my $self = shift;
    my $pfxlen = length(my $pfx = shift) + length(path_sep);
    confess 'No path?' unless @_;

    my $path = File::Spec->catfile($pfx, @_);
    {
        tree => $self,
        path => $path,
        relpath => [File::Spec->splitdir(substr($path, $pfxlen))],
    }
}

sub _blob_ls {
    my $self = shift;

    my $pfxlen = length(my $pfx = shift) + length(path_sep);
    map {
        tree => $self,
        path => $_,
        relpath => [File::Spec->splitdir(substr($_, $pfxlen))],
    },
    PFT::Util::list_files($pfx)
}

=item pic

Get a picture.

Accepts a list of strings which will be joined into the path of a
picture file.  Returns a C<PFT::Content::Blob> instance, which could
correspond to a non-existing file. The caller might create it (e.g. by
copying a picture on the corresponding path).

=cut

sub pic {
    my $self = shift;
    PFT::Content::Picture->new($self->_blob($self->dir_pics, @_))
}

=item pics_ls

List all pictures.

=cut

sub pics_ls {
    my $self = shift;
    map PFT::Content::Picture->new($_), $self->_blob_ls($self->dir_pics)
}

=item attachment

Get an attachment.

Accepts a list of strings which will be joined into the path of an
attachment file.  Returns a C<PFT::Content::Blob> instance, which could
correspond to a non-existing file. The caller might create it (e.g. by
copying a file on the corresponding path).

Note that the input path should be made by strings in encoded form, in
order to match the filesystem path.

=cut

sub attachment {
    my $self = shift;
    PFT::Content::Attachment->new($self->_blob($self->dir_attachments, @_))
}

=item attachments_ls

List all attachments.

=cut

sub attachments_ls {
    my $self = shift;
    map PFT::Content::Attachment->new($_),
        $self->_blob_ls($self->dir_attachments)
}

sub _blog_from_path {
    my($self, $path) = @_;
    my $h = eval { PFT::Header->load($path) };
    $h or carp("Loading $path: " . $@ =~ s/ at .*$//rs);

    PFT::Content::Blog->new({
        tree => $self,
        path => $path,
        name => $h ? $h->title : '?',
    })
}

sub _path_to_date {
    my($self, $path) = @_;

    my $rel = File::Spec->abs2rel($path, $self->dir_blog);
    return undef if index($rel, File::Spec->updir) >= 0;

    my($ym, $dt) = File::Spec->splitdir($rel);

    PFT::Date->new(
        substr($ym, 0, 4),
        substr($ym, 5, 2),
        defined($dt) ? substr($dt, 0, 2) : do {
            $ym =~ /^\d{4}-\d{2}.month$/
                or confess "Unexpected $ym for $path";
            undef
        }
    )
}

=item blog_back

Go back in blog history of a number of days, return the entries
corresponding to that date.

Expects one optional argument as the number of backward days in the blog
history. If such argument is not provided, it defaults to 0, returning the
entries of the latest edit day.

Please note that only days containing entries really count. If a blog had
one entry today, no entry for yesterday and one the day before yesterday,
C<blog_back(0)> will return today's entry, and C<blog_back(1)> will return
the entry of two days ago.

Returns a list PFT::Content::Blog object, possibly empty if the blog does
not have that many days.

=cut

sub blog_back {
    my $self = shift;
    my $back = shift || 0;

    confess 'Negative back?' if $back < 0;

    my @paths_and_dates =
        sort { $b->[1] <=> $a->[1] }
        map [$_, $self->_path_to_date($_)],
        PFT::Util::locale_glob(
            File::Spec->catfile($self->dir_blog, '*', '*')
        );

    my %dates;
    my @out;
    $back ++;   # Instead of doing $seen_dates == $back + 1 at every loop
    foreach (@paths_and_dates) {
        my($path, $date) = @$_;
        $dates{$date}++;

        my $seen_dates = keys %dates;
        if ($seen_dates == $back) {
            my $hdr = eval { PFT::Header->load($path) }
                or confess "Loading header of $path: " . $@ =~ s/ at .*$//rs;

            push @out => PFT::Content::Blog->new({
                tree => $self,
                path => $path,
                name => $hdr->title,
            });
        }
        last if $seen_dates > $back;
    }

    @out;
}

=item blog_at

Go back in blog history to a certain date.

Expects as argument a C<PFT::Date> item indicating a date to seek for blog
entries.

Returns a possibly empty list of C<PFT::Content::Blog> objects corresponding
to the zero, one or more entries in the specified date.

=cut

sub blog_at {
    my($self, $date) = @_;

    confess "Expecting date" unless defined($date) && $date->isa('PFT::Date');

    my $y = defined($date->y) ? sprintf('%04d', $date->y) : '*';
    my $m = defined($date->m) ? sprintf('%02d', $date->m) : '*';
    my $d = defined($date->d) ? sprintf('%02d', $date->d) : '*';

    map $self->_blog_from_path($_), PFT::Util::locale_glob(
        File::Spec->catfile($self->dir_blog, "$y-$m", "$d-*")
    );
}

=item detect_date

Given a C<PFT::Content::File> object (or any subclass) determines the
corresponding date by analyzing the path. Returns a C<PFT::Date> object or
undef if the page does not have date.

This function is helpful for checking inconsistency between the date
declared in headers and the date used on the file system.

=cut

sub detect_date {
    my($self, $content) = @_;

    unless ($content->isa('PFT::Content::File')) {
        confess 'Cannot determine path: ',
            ref $content || $content, ' is not not PFT::Content::File'
    }

    return undef unless $content->isa('PFT::Content::Blog');
    $self->_path_to_date($content->path) or die 'blog/month without date?';
}

=item detect_slug

Given a C<PFT::Content::File> object (or any subclass) determines the
corresponding slug by analyzing the path. Returns the slug or undef if the
content does not have a slug (e.g. months).

This function is helpful for checking inconsistency between the slug
declared in headers and the slug used on the file system.

=cut

sub detect_slug {
    my($self, $content) = @_;

    unless ($content->isa('PFT::Content::File')) {
        confess 'Cannot determine path: ',
            ref $content || $content, ' is not not PFT::Content::File'
    }

    return undef if $content->isa('PFT::Content::Month');

    my $fname = basename($content->path);
    $fname =~ s/^\d{2}-// if $content->isa('PFT::Content::Blog');
    $fname
}

=item was_renamed

Notify this content abstraction about the renaming of the corresponding
content file.  First parameter is the original name, second parameter is the
new name.

=cut

sub was_renamed {
    my $self = shift;
    my $d = dirname shift;

    # $ignored = shift;
    # Actually, we internally ignore the original name. The parameter is
    # maintained just in case we need it in future. For the moment we are
    # interested in getting rid of empty directories.
    opendir(my $dh, $d) or return;
    rmdir $d unless File::Spec->no_upwards(readdir $dh);
    close $dh;
}

=back

=cut

1;
