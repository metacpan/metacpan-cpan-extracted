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
package SVK::Command::Mkdir;
use strict;
use SVK::Version;  our $VERSION = $SVK::VERSION;

use base qw( SVK::Command::Commit );
use SVK::XD;
use SVK::I18N;
use SVK::Util qw( abs2rel get_anchor make_path );

sub options {
    ($_[0]->SUPER::options,
     'p|parent' => 'parent');
}

sub parse_arg {
    my ($self, @arg) = @_;
    return map { $self->{xd}->target_from_copath_maybe($_) } @arg;
}

sub lock {
    my $self = shift;
    $self->lock_coroot(@_);
}

sub ensure_parent {
    my ($self, $target) = @_;
    my $dst = $target->new;
    $dst->anchorify;
    die loc("Path %1 is not a checkout path.\n", $dst->report)
	unless $dst->isa('SVK::Path::Checkout');
    unless (-e $dst->copath) {
	die loc ("Parent directory %1 doesn't exist, use -p.\n", $dst->report)
	    unless $self->{parent};
	# this sucks
	my ($added_root) = make_path($dst->report);
	my $add = $self->command('add', { recursive => 1 });
	$add->run($add->parse_arg("$added_root"));
    }
    unless (-d $dst->copath) {
	die loc ("%1 is not a directory.\n", $dst->report);
    }

    if ($dst->root->check_path($dst->path_anchor) == $SVN::Node::unknown) {
	die loc ("Parent directory %1 is unknown, add first.\n", $dst->report);
    }
}

sub run {
    my ($self, @target) = @_;

    # XXX: better check for @target being the same type
    if (grep {$_->isa('SVK::Path::Checkout')} @target) {
	$self->ensure_parent($_) for @target;
	for (@target) {
	    make_path($_->{report});
	}
	for (@target) {
	    my $add = $self->command('add');
	    $add->run($add->parse_arg("$_->{report}"));
	}
	return ;
    }

    die loc("Mkdir for more than one depotpath is not supported yet.\n")
	if scalar @target > 1;

    # die if the path already exists
    my ($target) = @target;
    die loc("The path %1 already exists.\n", $target->depotpath)
        if $target->inspector->exist( $target->path );

    # otherwise, proceed
    $self->get_commit_message ();
    my ($anchor, $editor) = $self->get_dynamic_editor ($target);
    $editor->close_directory
	($editor->add_directory (abs2rel ($target->path, $anchor => undef, '/'),
				 0, undef, -1));
    $self->adjust_anchor ($editor);
    $self->finalize_dynamic_editor ($editor);
    return;
}

1;

__DATA__

=head1 NAME

SVK::Command::Mkdir - Create a versioned directory

=head1 SYNOPSIS

 mkdir DEPOTPATH
 mkdir PATH...

=head1 OPTIONS

 -p [--parent]          : create intermediate directories as required
 -m [--message] MESSAGE : specify commit message MESSAGE
 -F [--file] FILENAME   : read commit message from FILENAME
 --template             : use the specified message as the template to edit
 --encoding ENC         : treat -m/-F value as being in charset encoding ENC
 -P [--patch] NAME      : instead of commit, save this change as a patch
 -S [--sign]            : sign this change
 -C [--check-only]      : try operation but make no changes
 --direct               : commit directly even if the path is mirrored

