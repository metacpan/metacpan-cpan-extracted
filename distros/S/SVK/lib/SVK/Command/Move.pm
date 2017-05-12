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
package SVK::Command::Move;
use strict;
use SVK::Version;  our $VERSION = $SVK::VERSION;
use base qw( SVK::Command::Copy );
use SVK::Util qw ( abs2rel );
use SVK::I18N;

sub lock {
    my $self = shift;
    $self->lock_coroot(@_);
}

sub handle_direct_item {
    my $self = shift;
    my ($editor, $anchor, $m, $src, $dst) = @_;
    my ($srcm) = $self->under_mirror ($src);
    my $call;
    if ($srcm && $srcm->path eq $src->path) {
	# XXX: this should be in svk::mirror
	my $props = $src->root->node_proplist($src->path);
	# this is very annoying: for inejecting an additional
	# editor call, has to give callback to Command::Copy's
	# handle_direct_item
	$call = sub {
	    $editor->change_dir_prop($_[0], $_, $props->{$_},
				     )
 		for grep { m/^svm:/ } keys %$props;
	};
	push @{$self->{post_process_mirror}}, [$src->path, $dst->path];
    }
    $self->SUPER::handle_direct_item (@_, $call);

    $editor->delete_entry(abs2rel ($src->path, $anchor => undef, '/'),
                          $src->revision, 0);
    $self->adjust_anchor ($editor);
}

sub handle_co_item {
    my ($self, $src, $dst) = @_;
    $self->SUPER::handle_co_item ($src->new, $dst); # might be modified
    $self->{xd}->do_delete($src);
}

sub run {
    my $self = shift;
    my $src = $_[0];
    my $ret = $self->SUPER::run(@_);
    if ($self->{post_process_mirror}) {
	# XXX: also should set svm:incomplete revprop
	# should be in SVK::Mirror as well
	my $mstring = $src->root->node_prop('/', 'svm:mirror');
	for (@{$self->{post_process_mirror}}) {
	    my ($from, $to) = @$_;
	    $mstring =~ s/^\Q$from\E$/$to/;
	}
	my $cmd = $self->command('propset', { revision => undef,
					      message => 'svk: fix-up for mirror move' });
	$cmd->run('svm:mirror', $mstring, $src->new(path => '/'));
    }
    return $ret;
}

__DATA__

=head1 NAME

SVK::Command::Move - Move a file or directory

=head1 SYNOPSIS

 move DEPOTPATH1 DEPOTPATH2

=head1 OPTIONS

 -r [--revision] REV    : act on revision REV instead of the head revision
 -p [--parent]          : create intermediate directories as required
 -q [--quiet]           : print as little as possible
 -m [--message] MESSAGE : specify commit message MESSAGE
 -F [--file] FILENAME   : read commit message from FILENAME
 --template             : use the specified message as the template to edit
 --encoding ENC         : treat -m/-F value as being in charset encoding ENC
 -P [--patch] NAME      : instead of commit, save this change as a patch
 -S [--sign]            : sign this change
 -C [--check-only]      : try operation but make no changes
 --direct               : commit directly even if the path is mirrored

