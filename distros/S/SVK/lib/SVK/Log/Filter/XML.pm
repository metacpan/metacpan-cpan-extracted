# BEGIN BPS TAGGED BLOCK {{{
# COPYRIGHT:
# 
# This software is Copyright (c) 2003-2008 Best Practical Solutions, LLC
#                                          <clkao@bestpractical.com>
# 
# (Except where explicitly superseded by other copyright notices)
# 
# 
# LICENSE:
# 
# 
# This program is free software; you can redistribute it and/or
# modify it under the terms of either:
# 
#   a) Version 2 of the GNU General Public License.  You should have
#      received a copy of the GNU General Public License along with this
#      program.  If not, write to the Free Software Foundation, Inc., 51
#      Franklin Street, Fifth Floor, Boston, MA 02110-1301 or visit
#      their web page on the internet at
#      http://www.gnu.org/copyleft/gpl.html.
# 
#   b) Version 1 of Perl's "Artistic License".  You should have received
#      a copy of the Artistic License with this package, in the file
#      named "ARTISTIC".  The license is also available at
#      http://opensource.org/licenses/artistic-license.php.
# 
# This work is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
# 
# CONTRIBUTION SUBMISSION POLICY:
# 
# (The following paragraph is not intended to limit the rights granted
# to you to modify and distribute this software under the terms of the
# GNU General Public License and is only of importance to you if you
# choose to contribute your changes and enhancements to the community
# by submitting them to Best Practical Solutions, LLC.)
# 
# By intentionally submitting any modifications, corrections or
# derivatives to this work, or any other work intended for use with SVK,
# to Best Practical Solutions, LLC, you confirm that you are the
# copyright holder for those contributions and you grant Best Practical
# Solutions, LLC a nonexclusive, worldwide, irrevocable, royalty-free,
# perpetual, license to use, copy, create derivative works based on
# those contributions, and sublicense and distribute those contributions
# and any derivatives thereof.
# 
# END BPS TAGGED BLOCK }}}
package SVK::Log::Filter::XML;
use strict;
use warnings;

use base qw( SVK::Log::Filter::Output );

sub header {
    print qq{<?xml version="1.0" encoding="utf-8"?>\n<log>\n};
}

sub revision {
    my ($self, $args) = @_;
    my ($stash, $rev, $props) = @{$args}{qw( stash rev props )};

    # extract interesting revision properties
    my          (    $author,    $date,    $log ) =
    @{$props}{qw( svn:author  svn:date  svn:log )};

    my $original
        = format_original_revision( $stash, $rev, $args->{get_remoterev} );
    print qq{<logentry revision="$rev"$original>\n};

    print "<author>$author</author>\n" if defined $author;
    print "<date>$date</date>\n"       if defined $date;

    # display the paths that were modified by this revision
    print_changed_details( $args->{paths} ) if $stash->{verbose};

    if ( defined $log and !$stash->{quiet} ) {
        $log =~ s/&/&amp;/g;
        $log =~ s/</&lt;/g;
        $log =~ s/>/&gt;/g;
        print "<msg>$log</msg>\n";
    }

    print qq{</logentry>\n};
}

sub footer {
    print "</log>\n";
}

sub format_original_revision {
    my ( $stash, $rev, $get_remoterev ) = @_;

    my $remoterev = $get_remoterev->($rev) if $get_remoterev;

    return q{} if !$remoterev;
    return qq{ original="$remoterev"};
}

sub print_changed_details {
    my ($changed) = @_;

    print "<paths>\n";

    for my $changed_path ( $changed->paths() ) {
        print '<path';    # start <path>

        # show file history
        if ( $changed_path->is_copy() ) {
            my ( $copyfrom_rev, $copyfrom_path )
                = $changed_path->copied_from();
            print qq{ copyfrom-path="$copyfrom_path"};
            print qq{ copyfrom-rev="$copyfrom_rev"};
        }

        # make an SVN-compatible action
        my $action = $changed_path->action();
        if ( $action eq ' ' ) {
            $action = $changed_path->property_action();
        }

        # show the action and path
        print qq{ action="$action">};    # close <path>
        print $changed_path->path(), "</path>\n";
    }

    print "</paths>\n";
}

1;

__END__

=head1 NAME

SVK::Log::Filter::XML - display log messages in XML format

=head1 SYNOPSIS

    > svk log --xml
    <?xml version="1.0" encoding="utf-8"?>
    <log>
    <logentry revision="1234" original="456">
    <author>author</author>
    <date>2006-05-16T15:43:28.889532Z</date>
    <msg>This is the commit message for the revision.</msg>
    </logentry>
    </log>
    > svk log --output xml
    ...

=head1 DESCRIPTION

The XML filter is an output filter for displaying log messages in XML format.
The organization of the XML format should be self-explanatory after a little
experimentation.  The format is designed to be compatible with Subversion's
XML output, so you should be able to use tools like
L<http://ch.tudelft.nl/~arthur/svn2cl/> without any modification.  However,
since SVK supports arbitary log filters (see L<SVK::Log::Filter> for details
on writing one), it may be easier to write your own output format than to
process the XML.

This filter is invoked implicitly when you specify the "--xml" argument to
SVK's log command.  Two arguments to the log command modify XML's behavior.

=head2 quiet

Providing this command-line option to the log command prevents the XML filter
from displaying the contents of the log message.  All other information is
displayed as usual.

=head2 verbose

Providing this command-line option to the log command makes the XML filter
display history information for each revision.  The history includes the kind
of modification (modify, add, delete) and any copy history for each path that
was modified in the revision.


=head1 STASH/PROPERTY MODIFICATIONS

XML leaves all properties and the stash intact.

