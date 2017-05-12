# PurpleWiki::Search::IrcLogger.pm
# vi:ai:sm:et:sw=4:ts=4
#
# $Id: IrcLogger.pm 352 2004-05-08 22:00:33Z cdent $
#
# A Search Module for irclogger (see
# http://collab.blueoxen.net/forums/tools-yak/2003-12/msg00003.html
# )
#
# A sublcass of the Arts module as they use the same file format.
#
# FIXME: Change the Arts module to WikiText and make both Arts and
# IrcLogger subclasses of that.
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
#

package PurpleWiki::Search::IrcLogger;

use strict;
use base 'PurpleWiki::Search::Arts';
use PurpleWiki::Search::Result;
use AppConfig;

our $VERSION;
$VERSION = sprintf("%d", q$Id: IrcLogger.pm 352 2004-05-08 22:00:33Z cdent $ =~ /\s(\d+)\s/);

# AppConfig values from the irclogger config file
my @CONFIG = qw(channel wikiconfig url logfile);

# The regular expression used for matching filenames
my $FILE_MATCH = 'irclog\.\d+\.wiki';

sub _initRepository {
    my $self = shift;

    # open the logger config files and get the relevant info
    # and translate it to arts style
    my %config;

    foreach my $configFile (@{$self->config()->IrcLogConfig()}) {
        my $configRef = $self->_initConfig($configFile);

        my $channel = $configRef->channel();
        $config{$channel}{purpleConfig} = $configRef->wikiconfig();

        my $url = $configRef->url();
        $url =~ s/\/[^\/]+$//;
        $config{$channel}{urlprefix} = $url;

        my $files = $configRef->logfile();
        $files =~ s/\/[^\/]+$//;
        $config{$channel}{repository} = $files;
    }

    # collect information on the repository locations
    my %repositories;

    foreach my $repository (keys(%config)) {
        if ($config{$repository}{purpleConfig} =
            $self->{config}->DataDir()) {
            $repositories{$repository} = $config{$repository}{repository};
        }
    }

    # FIXME: its redundant to have both of these but I wanted easy
    #        access
    $self->{repositoryConfig} = \%config;
    $self->{repositories} = \%repositories;

    return $self;
}

# initialize the irclogger config
# taken from irclogger itself
sub _initConfig {
    my $self = shift;
    my $file = shift;

    $self->{fileMatch} = $FILE_MATCH;

    my $config;

    $config = AppConfig->new({
            CREATE => 1,
            GLOBAL => {
                EXPAND => AppConfig::EXPAND_VAR,
            },
        });

    foreach my $var (@CONFIG) {
        $config->define($var, {
                ARGCOUNT => AppConfig::ARGCOUNT_ONE,
            });
    }

    $config->file($file) || die "unable to parse config file: $file";

    return $config;
}

1;

__END__

=head1 NAME

PurpleWiki::Search::IrcLogger - Search IrcLogger Repositories

=head1 SYNOPSIS

This module adds searching of IrcLogger log files to the 
PurpleWiki modular search system. IrcLogger files are stored as
flat text files in PurpleWiki wikitext format.

=head1 DESCRIPTION

IrcLogger is a tool to log irc conversations. IRC text is saved
to text files in PurpleWiki wikitext format. More information
on IrcLogger is available at:
  
  http://collab.blueoxen.net/forums/tools-yak/2003-12/msg00003.html

To add an IrcLogger collection to a PurpleWiki search the IrcLogger
should be using the same L<PurpleWiki::Sequence> as the wiki. In 
addition the following should be added to the PurpleWiki configuration
file F<config>:

  SearchModule = IrcLogger
  IrcLogConfig = /path/to/irclogger.config

This module is a subclass of L<PurpleWiki::Search::Arts>. Most of the
work is done there. This module gathers configuration information.

Multiple IRC logs can be search by adding additional IrcLogConfig lines
to the F<config> file.

=head1 METHODS

See L<PurpleWiki::Search::Interface>.

=head1 AUTHOR

Chris Dent, E<lt>cdent@blueoxen.orgE<gt>

=head1 SEE ALSO

L<PurpleWiki::Search::Arts>.
L<PurpleWiki::Search::Interface>.

=cut

