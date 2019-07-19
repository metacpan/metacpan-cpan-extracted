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
package PFT::Content::Blob v1.3.0;

use v5.16;

use strict;
use warnings;
use utf8;

=pod

=encoding utf8

=head1 NAME

PFT::Content::Blob - Binary file

=head1 SYNOPSIS

    use PFT::Content::Blob;

    my $p = PFT::Content::Blob->new({
        tree    => $tree,
        path    => $path,
        relpath => ['animals', 'cats', 'meow.png'], # decoded strings
    })

=head1 DESCRIPTION

C<PFT::Content::Blob> is the basetype for all binary-based content files.
It inherits from C<PFT::Content::File> and has two specific subtypes:
C<PFT::Content::Picture> and C<PFT::Content::Attachment>.

=cut

use parent 'PFT::Content::File';

use Carp;

sub new {
    my $cls = shift;
    my $params = shift;

    my $self = $cls->SUPER::new($params);
    my $relpath = $params->{relpath};
    confess 'Invalid relpath' unless ref $relpath eq 'ARRAY';
    $self->{relpath} = $relpath;
    $self;
}

=head2 Properties

=over

=item relpath

Relative path in form of a list.

A good use for it could be, concatenating it using File::Spec->catfile.

=cut

sub relpath {
    @{shift->{relpath}}
}

=back

=cut

1
