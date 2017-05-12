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
package SVK::Log::Filter::Std;

use base qw( SVK::Log::Filter::Output );

use SVK::I18N;
use SVK::Util qw( get_encoding reformat_svn_date );
use SVK::Logger;

our $sep;

sub setup {
    my ($self, $args) = @_;
    my $stash = $args->{stash};

    $sep = $stash->{verbatim} || $stash->{no_sep} ? '' : ('-' x 70)."\n";
    $logger->info ($sep) if $sep;

    # avoid get_encoding() calls for each revision
    $self->{encoding} = get_encoding();
}

sub revision {
    my ($self, $args) = @_;
    my ($stash, $rev, $props) = @{$args}{qw( stash rev props )};

    # get short names for attributes
    my            ( $indent, $verbatim, $quiet )
    = @{$stash}{qw(  indent   verbatim   quiet )};


    my ( $author, $date ) = @{$props}{qw/svn:author svn:date/};
    my $message = $sep;   # assume quiet
    if (!$quiet) {
        $message  = $indent ? '' : "\n";
        $message .= $props->{'svn:log'} . "\n$sep";
    }

    # clean up the date
    $date = reformat_svn_date("%Y-%m-%d %T %z", $date);

    $author = loc('(no author)') if !defined($author) or !length($author);
    if ( !$verbatim ) {
        $logger->info ( $indent . 
	    fancy_rev( $stash, $rev, $args->{get_remoterev} ) .
	    ":  $author | $date");
    }

    # display the paths that were modified by this revision
    if ( $stash->{verbose} ) {
        $logger->info ( build_changed_details( $stash, $args->{paths}, $self->{encoding} ));
    }

    $message =~ s/^/$indent/mg if $indent and !$verbatim;
    require Encode;
    Encode::from_to( $message, 'UTF-8', $self->{encoding} );
    $logger->info($message);
}

sub fancy_rev {
    my ( $stash, $rev, $get_remoterev ) = @_;

    # find the remote revision number (if possible)
    my $host          = $stash->{host};
    my $remoterev     = $get_remoterev->($rev) if $get_remoterev;

    $host = '@' . $host       if length($host);
    return "r$rev$host"       if !$remoterev;
    return "r$remoterev$host" if $stash->{remote_only};

    return "r$rev$host (orig r$remoterev)";
}

sub build_changed_details {
    my ($stash, $changed, $encoding) = @_;

    # get short names for some useful quantities
    my $indent   = $stash->{indent};

    my $output = '';

    $output .= $indent . loc("Changed paths:\n");
    for my $changed_path ( $changed->paths() ) {
        my ( $copyfrom_rev, $copyfrom_path ) =  $changed_path->copied_from();
        my $action     = $changed_path->action();
        my $propaction = $changed_path->property_action();
        my $status     = $action . $propaction;

        # encode the changed path in the local encoding
        my $encoded_path = $changed_path->path();
        Encode::from_to( $encoded_path, 'utf8', $encoding );

        # finally, we can print the details about the changed file
        $output .= $indent . "  $status $encoded_path";
        if ( defined $copyfrom_path ) {
            Encode::from_to( $copyfrom_path, 'utf8', $encoding );
            $output .= ' ';
            $output .= loc( "(from %1:%2)", $copyfrom_path, $copyfrom_rev );
        }
        $output .= "\n";
    }

    return $output;
}

1;


__END__

=head1 NAME

SVK::Log::Filter::Std - display log messages in standard SVK format

=head1 SYNOPSIS

    > svk log
    ----------------------------------------------------------------------
    r1234 (orig r456):  author | 2006-05-15 09:28:52 -0600

    This is the commit message for the revision.
    ----------------------------------------------------------------------
    > svk log --output std
    ...

=head1 DESCRIPTION

The Std filter is the standard output filter for displaying log messages.  The
log format is designed to be similar to the output of Subversion's log
command.  Two arguments to the log command modify the standard output format.

=head2 quiet

Providing this command-line option to the log command prevents the contents of
the log message from being displayed.  All other information is displayed as
usual.

=head2 verbose

Providing this command-line option to the log command displays history
information for each revision.  The history includes the kind of modification
(modify, add, delete) and any copy history for each path that was modified in
the revision.


=head1 STASH/PROPERTY MODIFICATIONS

Std leaves all properties and the stash intact.

