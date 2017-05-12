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
package SVK::Root::View;
use strict;
use warnings;

use base qw{ SVK::Root };

__PACKAGE__->mk_accessors(qw(view));

use Scalar::Util 'weaken';
use SVK::Util 'is_path_inside';

sub txn_root {
    my ($self, $pool) = @_;
    my $newpool = SVN::Pool->new;
    my $txn = $self->fs->begin_txn
	( $self->txn->base_revision,
	  $newpool );

    $self->_apply_view_to_txn($txn, $self->view, $self->txn->base_revision);

    return $self->new({ view => $self->view, txn => $txn,
			root => $txn->root($newpool), pool => $newpool });
}

sub get_revision_root {
    my ($self, $path, $rev, $pool) = @_;
    $path = $self->rename_check($path, $self->view->rename_map(''));
    return ( SVK::Root->new( {root => $self->root->fs->revision_root($rev, $pool)} ),
	     $path );
}

sub rename_check {
    my ($self, $path, $map) = @_;
    for (@$map) {
	my ($from, $to) = @$_;
	if (is_path_inside($path, $from)) {
	    my $newpath = $path;
	    $newpath =~ s/^\Q$from\E/$to/;
	    return $newpath;
	}
    }
    return $path;
}

sub new_from_view {
    my ($class, $fs, $view, $revision) = @_;
    my $pool = SVN::Pool->new;
    my $txn = $fs->begin_txn($revision, $view->pool);

    my $self = $class->new({ txn => $txn, root => $txn->root($pool),
			     view => $view, pool => $pool });

    $self->_apply_view_to_txn($txn, $view, $revision);

    return $self;
}

sub _apply_view_to_txn {
    my ($self, $txn, $view, $revision) = @_;
    my $root = $txn->root($view->pool);
    my $origroot = $root->fs->revision_root($revision);

    my $pool = SVN::Pool->new_default;
    for (@{$view->view_map}) {
	$pool->clear;
	my ($path, $orig) = @$_;

	if (defined $orig) {
	    # XXX: mkpdir
	    Carp::cluck if ref($origroot) ne '_p_svn_fs_root_t';
	    SVN::Fs::copy( $origroot, "$orig",
			   $root, "$path")
		    if $origroot->check_path("$orig");
	}
	else {
	    if ($path =~ m/\*$/) {
		my $parent = $path->parent;
		my $entries = $root->dir_entries("$parent");
		for (keys %$entries) {
		    $root->delete($parent->subdir($_)->stringify);
		}
	    }
	    else {
		$root->delete("$path");
	    }
	}
    }
    return;
}

1;
