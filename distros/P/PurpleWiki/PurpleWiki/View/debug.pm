# PurpleWiki::View::debug.pm
#
# $Id: debug.pm 444 2004-08-05 08:14:37Z eekim $
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

package PurpleWiki::View::debug;
use 5.005;
use strict;
use warnings;
use Carp;
use PurpleWiki::View::Driver;

############### Package Globals ###############

our $VERSION;
$VERSION = sprintf("%d", q$Id: debug.pm 444 2004-08-05 08:14:37Z eekim $ =~ /\s(\d+)\s/);

our @ISA = qw(PurpleWiki::View::Driver);


############### Overloaded Methods ###############

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = $class->SUPER::new(@_);

    # Object State
    $self->{outputString} = "";
    $self->{indentLevel} = -1;

    bless($self, $class);
    return $self;
}

sub view {
    my ($self, $wikiTree) = @_;
    $self->SUPER::view($wikiTree);

    my $title = $wikiTree->title || '';

    $self->{outputString} = 'title:' . $title . "\n" . 
                             $self->{outputString};
    return $self->{outputString};
}

sub recurse {
    my ($self, $nodeRef) = @_;

    # recurse() should never be called on an undefined node.
    if (not defined $nodeRef) {
        carp "Warning: tried to recurse on an undefined node\n";
        return;
    }

    if ($nodeRef->isa('PurpleWiki::StructuralNode')) {
        $self->traverse($nodeRef->content) if defined $nodeRef->content;
    }

    if (defined $nodeRef->children) {
        $self->{indentLevel}++;
        $self->traverse($nodeRef->children);
        $self->{indentLevel}--;
    }
}

#sub Main {
#    my ($self, $nodeRef) = @_;
#    if ($nodeRef->type =~ /^(section|indent|ul|ol|dl)$/) {
#        $self->{indentLevel}++;
#    }
#}

#sub Post {
#    my ($self, $nodeRef) = @_;
#    if ($nodeRef->type =~ /^(section|indent|ul|ol|dl)$/) {
#        $self->{indentLevel}--;
#    }
#}

sub sectionPre { shift->_headingWithNewline(@_) }
sub indentPre { shift->_headingWithNewline(@_) }
sub ulPre { shift->_headingWithNewline(@_) }
sub olPre { shift->_headingWithNewline(@_) }
sub dlPre { shift->_headingWithNewline(@_) }

sub hPre { shift->_heading(@_) }
sub pPre { shift->_heading(@_) }
sub liPre { shift->_heading(@_) }
sub ddPre { shift->_heading(@_) }
sub dtPre { shift->_heading(@_) }
sub prePre { shift->_heading(@_) }
sub sketchPre { shift->_heading(@_) }

sub bPre { &_showType(@_) }
sub iPre { &_showType(@_) }
sub ttPre { &_showType(@_) }
sub nowikiPre { &_showType(@_) }
sub transclusionPre { &_showType(@_) }
sub linkPre { &_showType(@_) }
sub urlPre { &_showType(@_) }
sub wikiwordPre { &_showType(@_) }
sub freelinkPre { &_showType(@_) }
sub imagePre { &_showType(@_) }

sub textMain { shift->{outputString} .= shift->content . "\n" }
sub nowikiMain { shift->{outputString} .= shift->content . "\n" }
sub transclusionMain { shift->{outputString} .= shift->content . "\n" }
sub linkMain { shift->{outputString} .= shift->content . "\n" }
sub urlMain { shift->{outputString} .= shift->content . "\n" }
sub wikiwordMain { shift->{outputString} .= shift->content . "\n" }
sub freelinkMain { shift->{outputString} .= shift->content . "\n" }
sub imageMain { shift->{outputString} .= shift->content . "\n" }


############### Private Methods ###############

sub _showType {
    my ($self, $nodeRef) = @_;
    $self->{outputString} .= uc($nodeRef->type) . ':';
}

sub _heading {
    my ($self, $nodeRef) = @_;
    $self->{outputString} .= ' 'x(2 * $self->{indentLevel});
    $self->{outputString} .= $nodeRef->type.":";
    $self->{outputString} .= $nodeRef->id.':' if ($nodeRef->id);
}

sub _headingWithNewline {
    my ($self, $nodeRef) = @_;
    $self->{outputString} .= ' 'x(2 * $self->{indentLevel});
    $self->{outputString} .= $nodeRef->type.":\n";
}
1;
__END__

=head1 NAME

PurpleWiki::View::debug - View Driver used for Debugging.

=head1 DESCRIPTION

Prints out a view of a PurpleWiki::Tree that is useful for debugging

=head1 OBJECT STATE

=head2 outputString 

This contains the current working copy of the text that is ultimately returned
by view().

=head1 METHODS

=head2 new()

Returns a new PurpleWiki::View::debug object.

=head2 view($wikiTree)

Returns the debugging output as a string of text.

=head1 AUTHORS

Matthew O'Connor, E<lt>matthew@canonical.orgE<gt>

Chris Dent, E<lt>cdent@blueoxen.orgE<gt>

Eugene Eric Kim, E<lt>eekim@blueoxen.orgE<gt>

=head1 SEE ALSO

L<PurpleWiki::View::Driver>

=cut
