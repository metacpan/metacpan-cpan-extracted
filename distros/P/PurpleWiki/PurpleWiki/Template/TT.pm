# PurpleWiki::Template::TT.pm
#
# $Id: TT.pm 445 2004-08-05 08:31:23Z eekim $
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

package PurpleWiki::Template::TT;

use 5.005;
use strict;
use base 'PurpleWiki::Template::Base';
use IO::Select;
use IPC::Open3;
use Template;

our $VERSION;
$VERSION = sprintf("%d", q$Id: TT.pm 445 2004-08-05 08:31:23Z eekim $ =~ /\s(\d+)\s/);

sub process {
    my $self = shift;
    my $file = shift;
    my $template = Template->new({ INCLUDE_PATH => [ $self->templateDir ],
                                   POST_CHOMP => 1 }) ||
        die Template->error(), "\n";
    my $output;

    if ($template->process("$file.tt", $self->vars, \$output)) {
        return $output;
    } else {
        die $template->error(), "\n";
    }
    # FIXME: Need to exit gracefully if error is returned.
}

1;
__END__

=head1 NAME

PurpleWiki::Template::TT - Template Toolkit template driver.

=head1 SYNOPSIS

  use PurpleWiki::Template::TT;

=head1 DESCRIPTION



=head1 FILTERS

php filter

=head1 METHODS

=head2 process($file)

Returns the root StructuralNode object.


=head1 AUTHORS

Eugene Eric Kim, E<lt>eekim@blueoxen.orgE<gt>

=cut
