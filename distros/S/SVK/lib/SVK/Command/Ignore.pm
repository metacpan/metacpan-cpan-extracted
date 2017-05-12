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
package SVK::Command::Ignore;
use strict;
use SVK::Version;  our $VERSION = $SVK::VERSION;
use base qw( SVK::Command );

use SVK::Logger;
use SVK::Util qw ( abs2rel );

sub parse_arg {
    my ($self, @arg) = @_;
    return unless @arg;
    return map { $self->arg_copath($_) } @arg;
}

sub lock {
    my $self = shift;

    my $condensed = $self->{xd}->target_condensed(@_);
    $self->{xd}->lock($condensed->copath_anchor);
}

sub do_ignore {
    my $self = shift;
    my $target = shift;

    my $report = $target->report;

    $target->anchorify;

    my $filename = $target->copath_target;

    my $current_props = $target->root->node_proplist($target->path_anchor);

    my $svn_ignore = $current_props->{'svn:ignore'};
    $svn_ignore = '' unless defined $svn_ignore;

    my $current_ignore_re = $self->{xd}->ignore($svn_ignore);
    if ($filename =~ m/$current_ignore_re/) {
        $logger->info( "Already ignoring '$report'");
    } else {
        $svn_ignore .= "\n"
          if length $svn_ignore and substr($svn_ignore, -1, 1) ne "\n";
        $svn_ignore .= "$filename\n";

        $self->{xd}->do_propset
          ( $target,
           propname => 'svn:ignore',
           propvalue => $svn_ignore,
          );
    }
}

sub run {
    my ($self, @targets) = @_;
    $SVN::Error::handler = \&SVN::Error::confess_on_error;

    $self->do_ignore($_) for @targets;
    return;
}

1;

__DATA__

=head1 NAME

SVK::Command::Ignore - Ignore files by setting svn:ignore property

=head1 SYNOPSIS

 ignore PATH...

=head1 DESCRIPTION

Adds the given paths to the 'svn:ignore' properties of their parents,
if they are not already there.

(If a given path contains a wildcard character (*, ?, [, or \), the
results are undefined -- specifically, the result of the check to see
if the entry is already there may not be what you expected.  Currently
it will not try to escape any such entries before adding them.)

To tell svk to start paying attention to a file again, use the command
'svk pe svn:ignore' to manually edit the ignore list.
