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
package SVK::Path::Txn;
use strict;
use base 'SVK::Path';
__PACKAGE__->mk_shared_accessors(qw(txn));

sub _get_inspector {
    my $self = shift;

    Carp::cluck unless $self->repos;
    $self->txn($self->repos->fs_begin_txn_for_commit
	       ($self->revision,
		undef, undef, $self->pool))
	unless $self->txn;

    return SVK::Inspector::Root->new
       ({ root => $self->txn->root($self->pool),
	  istxn => 1,
          _pool => $self->pool,
          anchor => $self->path_anchor });
}

sub get_editor {
    my ($self, %arg) = @_;
    my $inspector = $self->inspector;

    my $callback;
    my ($editor, $post_handler) =
	$self->_commit_editor($self->txn, $callback, $self->pool);

    require SVK::Editor::Combiner;
    return (SVK::Editor::Combiner->new(_editor => [ $editor ]),
	    $inspector,
	    txn => $self->txn,
	    post_handler => $post_handler,
	    cb_rev => sub { $self->revision },
	    cb_copyfrom => sub { $self->as_url(1, @_) });
}

sub root {
    my $self = shift;
    return $self->inspector->root;
}

sub as_depotpath {
    my $self = shift;
    my $depotpath = $self->mclone(txn => undef);
    bless $depotpath, 'SVK::Path';
    return $depotpath;
}

sub prev {
    my ($self) = shift;

    my $base = $self->as_depotpath;
    unless (%{ $self->root->paths_changed }) {
	$base = $base->prev;
    }
    return $base;
}

1;
