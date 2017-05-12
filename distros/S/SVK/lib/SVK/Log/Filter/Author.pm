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
package SVK::Log::Filter::Author;

use strict;
use warnings;
use base qw( SVK::Log::Filter::Selection );

use SVK::I18N;
use List::MoreUtils qw( any );

sub setup {
    my ($self) = @_;

    my $search = $self->{argument}
        or die loc("Author: at least one author name is required.\n");

    my @matching_authors = split /\s* , \s*/xms, $search;
    $self->{names} = \@matching_authors;
    $self->{wants_none} = grep { $_ eq '(none)' } @matching_authors;
}

sub revision {
    my ($self, $args) = @_;
    my $props = $args->{props};

    # look for a matching, non-existent author
    my $author = $props->{'svn:author'};
    if ( !defined $author ) {
        return if $self->{wants_none};
        $self->pipeline('next');
    }

    # look for a matching, existent author
    return if any { $_ eq $author } @{ $self->{names} };

    # no match, so skip to the next revision
    $self->pipeline('next');
}

1;

__END__

=head1 SYNOPSIS

SVK::Log::Filter::Author - search revisions for given authors

=head1 DESCRIPTION

The Author filter accepts a comma-separated list of author names.  If the
svn:author property is equal to any of the names, the revision is allowed to
continue down the pipeline.  Otherwise, the revision is skipped.  The special
author name "(none)" means to look for revisions with no svn:author property.

For example, to search for all commits by either "jack" or "jill" one might do

    svk log --filter "author jill,jack"

To locate those revisions without an author, this command may be used

    svk log --filter "author (none)"

Of course "(none)" may be used in a list with other authors

    svk log --filter "author jill,(none)"

=head1 STASH/PROPERTY MODIFICATIONS

Author leaves all properties and the stash intact.

