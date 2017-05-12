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
package SVK::Log::Filter::Head;

use strict;
use warnings;
use SVK::I18N;
use base qw( SVK::Log::Filter::Selection );

sub setup {
    my ($self) = @_;

    my $argument = $self->{argument};
    die loc("Head: '%1' is not numeric.\n", $argument)
        if $argument !~ /\A \d+\s* \z/xms;

    $self->{remaining} = $argument;
}

sub revision {
    my ($self, $args) = @_;
    $self->pipeline('last') if --$self->{remaining} < 0;
}

1;

__END__

=head1 SYNOPSIS

SVK::Log::Filter::Head - pass the first N revisions

=head1 DESCRIPTION

The Head filter requires a single integer as its argument.  The integer
represents the number of revisions that the filter should allow to pass down
the filter pipeline.  Head only counts revisions that it sees, so if an
upstream filter causes the pipeline to skip a revision, Head won't (and can't)
count it.  As soon as Head has seen the specified number of revisions, it
stops the pipeline from processing any further revisions.

This filter is particularly useful when searching log messages for patterns
(see L<SVK::Log::Filter::Grep>).  For example, to view the first three
revisions with messages that match "foo", one might use

    svk log --filter "grep foo | head 3"


=head1 STASH/PROPERTY MODIFICATIONS

Head leaves all properties and the stash intact.

