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
package PFT::Content::Entry v1.3.0;

=encoding utf8

=head1 NAME

PFT::Content::Entry - Content edited by user.

=head1 SYNOPSIS

    use PFT::Content::Entry;

    my $p = PFT::Content::Entry->new({
        tree => $tree,
        path => $path,
        name => $name, 
    })

=head1 DESCRIPTION

C<PFT::Content::Entry> is the basetype for all text-based content files.
It inherits from C<PFT::Content::File> and has two specific subtypes:
C<PFT::Content::Blog> (representing an entry with date) and 
C<PFT::Content::Page> (representing an entry withouth date).

=back

=head2 Methods

=over

=cut

use utf8;
use v5.16;
use strict;
use warnings;

use parent 'PFT::Content::File';

use PFT::Header;
use PFT::Date;

use Encode;
use Encode::Locale;

use File::Spec;
use Carp;

=item open

Open the file, return a file handler. Sets the binmode according to the
locale.

=cut

sub open {
    my $self = shift;
    my $out = $self->SUPER::open(@_);
    binmode $out, 'encoding(locale)';
    $out;
}

=item header

Reads the header from the page.

Returns undef if the entry is not backed by a file. Croaks if the file
does not contain a healty header.

=cut

sub header {
    my $self = shift;
    return undef unless $self->exists;
    eval { PFT::Header->load($self->open('r')) }
        or croak $@ =~ s/ at .*$//rs;
}

=item read

Read the page.

In scalar context returns an open file descriptor configured with the
correct C<binmode> according to the header.  In list context returns the
header and the same descriptor. Returns C<undef> if the file does not exist.

Croaks if the header is broken.

=cut

sub read {
    my $self = shift;

    return undef unless $self->exists;
    my $fh = $self->open('r');

    # We read the header even if not required by the caller, since this
    # moves the cursor of the file descriptor. This allows the header to be
    # skipped and only the text to be returned.
    my $h = eval { PFT::Header->load($fh) }
        or croak $@ =~ s/ at .*$//rs;

    wantarray ? ($h, $fh) : $fh;
}

=item void

Evaluates as true if the entry is void, that is if the file does not exist,
or if it contains only the header.

=cut

sub void {
    my($h, $fh) = shift->read;
    return 1 unless defined $h;

    local $_;
    while (<$fh>) {
        /\S/ and return ''; # a non-whitespace exists.
    }

    1 # No content found.
}

=item set_header

Sets a new header, passed by parameter.

This will rewrite the file. Content will be maintained.

=cut

sub set_header {
    my $self = shift;
    my $hdr = shift;

    $hdr->isa('PFT::Header')
        or confess 'Must be PFT::Header';

    my @lines;
    if ($self->exists && !$self->empty) {
        my($old_hdr, $fh) = $self->read;
        @lines = <$fh>;
        close $fh;
    }

    my $fh = $self->open('w');
    $hdr->dump($fh);
    print $fh $_ foreach @lines;
}

=item make_consistent

Make page consistent with the filesystem tree.

=cut

sub make_consistent {

    my $self = shift;

    my $hdr = $self->header;
    my($done, $rename);

    my $pdate = $self->tree->detect_date($self);
    if (defined $pdate) {
        my $hdt = $hdr->date;
        if (defined($hdt) and defined($hdt->y) and defined($hdt->m)) {
            $rename ++ if $hdt <=> $pdate; # else date is just fine.
        } else {
            # The header does not declare a date, we figure it out from the
            # position in the filesystem and update it.
            $hdr->set_date($pdate);
            $self->set_header($hdr);
            $done ++;
        }
    } # else not in blog.

    if ($hdr->slug ne $self->tree->detect_slug($self)) {
        $rename ++;
    }

    if ($rename) {
        my $newpath = $self->tree->hdr_to_path($hdr);
        while (-e $newpath) {
            $newpath =~ s/(\d*)$/($1 || 0) + 1/e
        }
        $self->rename_as($newpath);
        $done ++;
    }

    $done
}

=back

=cut

1;
