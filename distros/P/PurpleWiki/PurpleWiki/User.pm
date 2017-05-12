# PurpleWiki::User.pm
# vi:sw=4:ts=4:ai:sm:et:tw=0
#
# $Id: User.pm 463 2004-08-09 01:31:48Z cdent $
#
# Copyright (c) Blue Oxen Associates 2002-2004.  All rights reserved.
#
# This file is part of PurpleWiki.  PurpleWiki is derived from:
#
#   UseModWiki v0.92          (c) Clifford A. Adams 2000-2001
#   AtisWiki v0.3             (c) Markus Denker 1998
#   CVWiki CVS-patches        (c) Peter Merel 1997
#   The Original WikiWikiWeb  (c) Ward Cunningham
#
# PurpleWiki is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the
#    Free Software Foundation, Inc.
#    59 Temple Place, Suite 330
#    Boston, MA 02111-1307 USA

package PurpleWiki::User;

use strict;
use PurpleWiki::Config;

our $VERSION;
$VERSION = sprintf("%d", q$Id: User.pm 463 2004-08-09 01:31:48Z cdent $ =~ /\s(\d+)\s/);

sub new {
    my $class = shift;
    my $userId = shift;
    my $self = {};
    $self->{config} = PurpleWiki::Config->instance();
    $self->{id} = $userId if ($userId);
    bless ($self, $class);
    return $self;
}

### accessors/mutators

sub id {
    my $self = shift;

    $self->{id} = shift if @_;
    return $self->{id};
}

sub username {
    my $self = shift;

    $self->{username} = shift if @_;
    return $self->{username};
}

sub tzOffset {
    my $self = shift;

    $self->{tzOffset} = shift if @_;
    return $self->{tzOffset};
}

sub createTime {
    my $self = shift;

    $self->{createTime} = shift if @_;
    return $self->{createTime};
}

sub createIp {
    my $self = shift;

    $self->{createIp} = shift if @_;
    return $self->{createIp};
}

# the following may eventually go away.  here mostly for backwards
# compatibility.

sub getField {
    my $self = shift;
    my $field = shift;

    return ($self->{$field} || '');
}

sub setField {
    my $self = shift;
    my $field = shift;
    my $value = shift;

    $self->{$field} = $value;
}

1;
__END__

=head1 NAME

PurpleWiki::User - PurpleWiki user class

=head1 SYNOPSIS

A class representation of a PurpleWiki user.

=head1 DESCRIPTION



=head1 METHODS

=head2 new($userId)

$userId is optional.

=head2 Accessors/Mutators

 id
 username
 tzOffset
 createTime
 createIp

=head2 Legacy Methods

 getField
 setField

Used for parameters without methods.  Right now, this includes all of
the UseMod preferences.  This needs to be reworked.

=head1 AUTHORS

Eugene Eric Kim, E<lt>eekim@blueoxen.orgE<gt>

=head1 SEE ALSO

L<PurpleWiki::Database::User::Base>

=cut
