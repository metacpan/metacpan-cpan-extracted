# PurpleWiki::View::rawtext.pm
#
# $Id: rawtext.pm 366 2004-05-19 19:22:17Z eekim $
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

package PurpleWiki::View::rawtext;
use 5.005;
use strict;
use warnings;
use PurpleWiki::Transclusion;
use PurpleWiki::View::Driver;

############### Package Globals ###############

our $VERSION;
$VERSION = sprintf("%d", q$Id: rawtext.pm 366 2004-05-19 19:22:17Z eekim $ =~ /\s(\d+)\s/);

our @ISA = qw(PurpleWiki::View::Driver);


############### Overloaded Methods ###############

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = $class->SUPER::new(@_);

    # Object State
    $self->{indentLevel} = 0;
    $self->{outputString} = "";
    $self->{listType} = "";
    $self->{initialIndent} = "";
    $self->{subsequentIndent} = "";
    $self->{listNumber} = 1;
    $self->{prevDefType} = "";
    $self->{links} = [];
    $self->{transcluder} = new PurpleWiki::Transclusion(
        config => $self->{config},
        url => $self->{url});

    bless($self, $class);
    return $self;
}

sub view {
    my ($self, $wikiTree) = @_;
    
    $self->SUPER::view($wikiTree);

    return $self->{outputString};
}

sub Pre {
    my ($self, $nodeRef) = @_;
    if ($nodeRef->type =~ /^(ul|ol|dl|indent|section)$/) {
        $self->{indentLevel}++;
    }
    $self->SUPER::Pre($nodeRef);
}

sub Post {
    my ($self, $nodeRef) = @_;
    if ($nodeRef->type =~ /^(ul|ol|dl|indent|section)$/) {
        $self->{indentLevel}--;
    }
    $self->SUPER::Post($nodeRef);
}

sub sectionPre { shift->_setIndent(@_) }
sub indentPre { shift->_setIndent(@_) }
sub ulPre { shift->_setIndent(@_) }
sub olPre { shift->_setIndent(@_) }
sub dlPre { shift->_setIndent(@_) }

sub ulMain { shift->_recurseList(@_) }
sub olMain { shift->_recurseList(@_) }

sub hPre { shift->_newLineSetIndent(@_) }
sub pPre { shift->_newLineSetIndent(@_) }
sub liPre { shift->_newLineSetIndent(@_) }
sub dtPre { shift->_newLineSetIndent(@_) }
sub prePre { shift->_newLineSetIndent(@_) }

sub hMain { shift->_structuralContent(@_) }
sub pMain { shift->_structuralContent(@_) }
sub liMain { shift->_structuralContent(@_) }
sub dtMain { shift->_structuralContent(@_) }
sub ddMain { shift->_structuralContent(@_) }
sub preMain { shift->_structuralContent(@_) }

sub hPost { shift->{outputString} .= "\n" }
sub pPost { shift->{outputString} .= "\n" }
sub liPost { shift->{outputString} .= "\n" }
sub prePost { shift->{outputString} .= "\n" }

sub dtPost { 
    my $self = shift;
    $self->{prevDefType} = 'dt';
    $self->{outputString} .= "\n";
}

sub ddPre {
    my $self = shift;
    $self->_setIndent(@_);
    if ($self->{prevDefType} eq 'dd') {
        $self->{outputString} .= "\n";
    }
}

sub ddPost {
    my $self = shift;
    $self->{prevDefType} = 'dd';
    $self->{outputString} .= "\n";
}

sub bPre { shift->{outputString} .= "*" }
sub bPost { shift->{outputString} .= "*" }

sub iPre { shift->{outputString} .= "_" }
sub iPost { shift->{outputString} .= "_" }

sub textMain { shift->{outputString} .= shift->content }
sub nowikiMain { shift->{outputString} .= shift->content }
sub transclusionMain {
    my ($self, $nodeRef) = @_;
    my $transcluded = $self->{transcluder}->get($nodeRef->content);
    if (ref $transcluded) {
        # Add the transcluded content into our tree if it's a reference
        $self->traverse($transcluded->content);
    } else {
        # Add the transcluded string to our output if it isn't a reference
        $self->{outputString} .= $transcluded;
    }
}
sub linkMain { shift->{outputString} .= shift->content }

sub transclusionPre { shift->{outputString} .= "transclude: " }

sub urlPre { shift->{outputString} .= shift->content }
sub wikiwordPre { shift->{outputString} .= shift->content }
sub freelinkPre { shift->{outputString} .= shift->content }
sub imagePre { shift->{outputString} .= shift->content }


############### Private Methods ###############

sub _recurseList {
    my ($self, $nodeRef) = @_;
    $self->{listType} = $nodeRef->type;
    $self->{listNumber} = 1 if $nodeRef->type eq 'ol';
    $self->recurse($nodeRef);
}

sub _newLineSetIndent {
    my $self = shift;
    $self->_setIndent(@_);
    $self->{outputString} .= "\n";
}

sub _structuralContent {
    my ($self, $nodeRef) = @_;

    if ($nodeRef->content) {
        my $tmp = $self->{outputString};
        $self->{outputString} = "";
        $self->traverse($nodeRef->content);
        my $nodeString = $self->{outputString};
        $self->{outputString} = $tmp;
        if ($nodeRef->type eq 'li') {
            if ($self->{listType} eq 'ul') {
                $nodeString = "* $nodeString";
            }
            elsif ($self->{listType} eq 'ol') {
                $nodeString = $self->{listNumber}.". $nodeString";
                $self->{listNumber}++;
            }
        }
        if ($nodeRef->type eq 'pre') {
            $self->{outputString} .= $nodeString;
        } else {
            $self->{outputString} .= $nodeString;
        }
    }
}

sub _setIndent {
    my ($self, $nodeRef) = @_;

    my $indent;
    my $initialOffset = 1;
    my $subsequentOffset = 1;
    my $subsequentMore = 0;
    my $listMore = 0;

    if ($nodeRef->type eq 'li') {
        $initialOffset = 2;
        $subsequentOffset = 2;
        $listMore = 2;

        if ($self->{listType} eq 'ul') {
            $subsequentMore = 2;
        } elsif ($self->{listType} eq 'ol') {
            $subsequentMore = 3;
        }
    } elsif ($nodeRef->type eq 'dt') {
        $initialOffset = 2;
        $subsequentOffset = 2;
    }

    $indent = 4*$self->{indentLevel} - 4*$initialOffset + $listMore;
    $self->{initialIndent} = ' ' x $indent;

    $indent = 4*$self->{indentLevel} - 4*$subsequentOffset + $subsequentMore 
              + $listMore;
    $self->{subsequentIndent} = ' ' x $indent;
}
1;
__END__

=head1 NAME

PurpleWiki::View::rawtext - View Driver used for Raw Text Output.

=head1 DESCRIPTION

Prints out a raw text view of a PurpleWiki::Tree.  No formatting or
nicities are done with regard to links or colomns.  Useful if you want
to convert nodes to text and then do things with that text.  For example,
transcluding into IRC via a Purple Number aware bot.

=head1 OBJECT STATE

=head2 outputString 

This contains the current working copy of the text that is ultimately returned
by view().

=head1 METHODS

=head2 new()

Returns a new PurpleWiki::View::text object.

=head2 view($wikiTree)

Returns the output as a string of text.

=head1 AUTHORS

Matthew O'Connor, E<lt>matthew@canonical.orgE<gt>

Chris Dent, E<lt>cdent@blueoxen.orgE<gt>

Eugene Eric Kim, E<lt>eekim@blueoxen.orgE<gt>

=head1 SEE ALSO

L<PurpleWiki::View::Driver>, L<PurpleWiki::View::text>

=cut
