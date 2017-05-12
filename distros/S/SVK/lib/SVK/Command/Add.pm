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
package SVK::Command::Add;
use strict;
use SVK::Version;  our $VERSION = $SVK::VERSION;

use base qw( SVK::Command );
use constant opt_recursive => 1;
use SVK::XD;
use SVK::I18N;
use SVK::Logger;
use SVK::Util qw( $SEP is_symlink mimetype_is_text to_native);

sub options {
    ('q|quiet'		=> 'quiet');
}

sub parse_arg {
    my ($self, @arg) = @_;
    return $self->arg_condensed(@arg);
}

sub lock {
    $_[0]->lock_target ($_[1]);
}

sub run {
    my ($self, $target) = @_;

    unless ($self->{recursive}) {
	die loc ("%1 already under version control.\n", $target->report)
	    unless $target->source->{targets};
	# check for multi-level targets
	for (@{$target->source->{targets}}) {
	    # XXX: consolidate sep for targets
	    my ($parent) = m{^(.*)[/\Q$SEP\E]}o or next;
	    die loc ("Please add the parent directory '%1' first.\n", $parent)
		unless $self->{xd}{checkout}->
		    get ($target->copath ($parent))->{'.schedule'};
	}
    }

    $self->{xd}->do_add(
        $target,
        recursive       => $self->{recursive},
        quiet           => $self->{quiet},
        unknown_verbose => $self->{recursive},
    );

    return;
}

1;

__DATA__

=head1 NAME

SVK::Command::Add - Put files and directories under version control

=head1 SYNOPSIS

 add [PATH...]

=head1 OPTIONS

 -N [--non-recursive]   : do not descend recursively
 -q [--quiet]           : do not display changed nodes

=head1 DESCRIPTION

Put files and directories under version control, scheduling
them for addition to repository.  They will be added in next commit.

