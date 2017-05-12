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
package SVK::Log::Filter::Grep;

use strict;
use warnings;
use SVK::I18N;
use base qw( SVK::Log::Filter::Selection );

sub setup {
    my ($self) = @_;

    my $search = $self->{argument};
    my $rx = eval "qr{$search}i"
        or die loc( "Grep: Invalid regular expression '%1'.\n", $search );

    $self->{pattern} = $rx;
}

sub revision {
    my ($self, $args) = @_;
    my $log = $args->{props}{'svn:log'};
    $self->pipeline('next') if $log !~ m/$self->{pattern}/;
}

1;

__END__

=head1 SYNOPSIS

SVK::Log::Filter::Grep - search log messages for a given pattern

=head1 DESCRIPTION

The Grep filter requires a single Perl pattern (regular expression) as its
argument.  The pattern is then applied to the svn:log property of each
revision it receives.  If the pattern matches, the revision is allowed to
continue down the pipeline.  If the pattern fails to match, the pipeline
immediately skips to the next revision.

The pattern is applied with the /i modifier (case insensitivity).  If you want
case-sensitivity or other modifications to the behavior of your pattern, you
must use the "(?imsx-imsx)" extended pattern (see "perldoc perlre" for
details).  For example, to search for log messages that match exactly the
characters "foo" you might use

    svk log --filter "grep (?-i)foo"

However, to search for "foo" without regards for case, one might try

    svk log --filter "grep foo"

The result of any capturing parentheses inside the pattern are B<not>
available.  If demand dictates, the Grep filter could be modified to place the
captured value somewhere in the stash for other filters to access.

If the pattern contains a pipe character ('|'), it must be escaped by
preceding it with a '\' character.  Otherwise, the portion of the pattern
after the pipe character is interpreted as the name of a log filter.

=head1 STASH/PROPERTY MODIFICATIONS

Grep leaves all properties and the stash intact.

