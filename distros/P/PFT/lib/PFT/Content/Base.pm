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
package PFT::Content::Base v1.3.0;

=encoding utf8

=head1 NAME

PFT::Content::Base - Base class for content

=head1 SYNOPSIS

    use parent 'PFT::Content::Base'

    sub new {
        my $cls = shift;
        ...
        $cls->SUPER::new({
            tree => $tree,
            name => $name,
        })
        ...
    }

=head1 DESCRIPTION

This class is a common base for for all C<PFT::Content::*> classes.

=cut

use utf8;
use v5.16;
use strict;
use warnings;

use Carp;

sub new {
    my $cls = shift;
    my $params = shift;

    exists $params->{$_} or confess "Missing param: $_"
        for qw/tree name/;

    bless {
        tree => $params->{tree},
        name => $params->{name},
    }, $cls
}

=head2 Properties

=over

=item tree

Path object

=item name

Name of the object

=cut

sub tree { shift->{tree} }

sub name { shift->{name} }

use overload
    '""' => sub {
        my $self = shift;
        ref($self) . '({name => "' . $self->{name} . '"})'
    },
    'cmp' => sub {
        my($self, $oth, $swap) = @_;
        my $out = $self->name cmp $oth->name;
        $swap ? -$out : $out;
    }
;

=back

=cut

1;
