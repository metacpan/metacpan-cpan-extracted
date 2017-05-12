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
package SVK::Command::Describe;
use strict;
use SVK::Version;  our $VERSION = $SVK::VERSION;

use base qw( SVK::Command::Diff SVK::Command::Log);
use SVK::XD;
use SVK::I18N;

sub options {
    ();
}

sub parse_arg {
    my ($self, @arg) = @_;
    return if $#arg < 0;

    # Allow user to type "svk describe r12345", for easy copy-and-paste
    # from "svk log".
    $arg[0] =~ s/^r(\d+\@?)$/$1/;

    # We need to find a depotroot for generating a diff that includes
    # the entire tree (not just where we might be now), and a
    # depotpath which is specific in order to do find_local_revs.
    # Note that if arg_co_maybe fails, then "svk desc" looks in //, so
    # just run any localrev calls through that.

    my $depotroot = $self->arg_depotroot($arg[1]);
    my $depotpath = $depotroot;
    {
        local $@;
        eval { $depotpath = $self->arg_co_maybe(defined $arg[1] ? $arg[1] : '')
                 ->as_depotpath->refresh_revision };
    }

    return ($arg[0], $depotroot, $depotpath);
}

sub run {
    my ($self, $chg, $target_root, $target_sub) = @_;
    my $rev = $self->resolve_revision($target_sub,$chg);
    if ($rev > $target_root->revision) {
        die loc("Depot /%1/ has no revision %2\n", $target_root->depotname, $rev);
    }
    $self->{revspec} = [$rev];
    $self->SVK::Command::Log::run ($target_root);
    $self->{revspec} = [$rev-1, $rev];
    $self->SVK::Command::Diff::run ($target_root);
}

1;

__DATA__

=head1 NAME

SVK::Command::Describe - Describe a change

=head1 SYNOPSIS

 describe REV [DEPOTPATH | PATH]

=head1 DESCRIPTION

Displays the change in revision number I<REV> in the specified depot.
It always shows the entire change even if you specified a particular target.
(I<REV> can optionally have the prefix C<r>, just like the revisions reported
from C<svk log>.)

=head1 OPTIONS

 None

