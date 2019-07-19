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
package PFT::Tree v1.3.0;

=encoding utf8

=head1 NAME

PFT::Tree - Filesystem tree mapping a PFT site

=head1 SYNOPSIS

    PFT::Tree->new();
    PFT::Tree->new($basedir);
    PFT::Tree->new($basedir, {create => 1});

=head1 DESCRIPTION

The structure is the following:

    ├── build
    ├── content
    │   └── ...
    ├── inject
    ├── pft.yaml
    └── templates

Where:

=over

=item C<content> is a directory is handled with a C<PFT::Content>
instance.

=item C<pft.yaml> is a configuration file handled with C<PFT::Conf>

=item The remaining directories are just created, but the content is not
handled by the C<PFT::Tree> structure.

=cut

use utf8;
use v5.16;
use strict;
use warnings;

use File::Spec;
use File::Path qw/make_path/;
use Carp;
use Cwd;

use PFT::Content;
use PFT::Conf;
use PFT::Map;

sub new {
    my($cls, $given, $opts) = @_;

    if ($opts->{create}) {
        defined $given or confess "Base dir is mandatory if creating";
        my $root = PFT::Conf::locate($given);
        if (defined $root and $root ne $given) {
            confess "Cannot nest. Found a root in $root";
        }
        my $self = bless { root => $given }, $cls;
        $self->_create();
        $self
    } elsif (defined(my $root = PFT::Conf::locate($given))) {
        bless { root => $root }, $cls;
    } else {
        croak 'Cannot find tree in ', $given || Cwd::cwd;
    }
}

sub _create {
    my $self = shift;
    make_path map({ $self->$_ } qw/
        dir_content
        dir_templates
        dir_inject
    /), {
        #verbose => 1,
        mode => 0711,
    };

    unless (PFT::Conf::isroot(my $root = $self->{root})) {
        PFT::Conf->new_default->save_to($root);
    }

    $self->content(create => 1);
}

=head2 Properties

=over 1

=item dir_content

=cut

sub dir_content { File::Spec->catdir(shift->{root}, 'content') }

sub dir_base { shift->{root} }
sub dir_templates { File::Spec->catdir(shift->{root}, 'templates') }
sub dir_inject { File::Spec->catdir(shift->{root}, 'inject') }
sub dir_build { File::Spec->catdir(shift->{root}, 'build') }

=item content

Returns a C<PFT::Content> object, abstracting the access to the I<content>
directory.

=cut

sub content { PFT::Content->new(shift->dir_content, {@_}) }

=item map

Returns a C<PFT::Map> object, abstracting the the content graph.

=cut

sub content_map { PFT::Map->new(shift->content) }

=item conf

Returns a C<PFT::Conf> object, abstracting the configuration file.

=cut

sub conf { PFT::Conf->new_load(shift->{root}) }

=back

=cut

1;
