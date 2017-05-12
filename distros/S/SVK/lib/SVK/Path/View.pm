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
package SVK::Path::View;
use strict;
use SVK::Version;  our $VERSION = $SVK::VERSION;
use SVK::I18N;
use SVK::Logger;
use base 'SVK::Path';

__PACKAGE__->mk_clonable_accessors(qw(source));
__PACKAGE__->mk_shared_accessors(qw(view));

use SVK::Util qw( abs2rel );
use SVK::Root::View;

sub _root {
    my $self = shift;

    return SVK::Root::View->new_from_view
	( $self->repos->fs,
	  $self->view, $self->source->revision );
}

sub refresh_revision {
    my $self = shift;

    $self->source->refresh_revision;
    $self->SUPER::refresh_revision;
    $self->_recreate_view;

    return $self;
}

sub get_editor {
    my ($self, %arg) = @_;
    my $anchor = $self->_to_pclass($self->path_anchor, 'Unix');
    my $map = $self->view->rename_map('');
    my $actual_anchor = $self->root->rename_check($anchor, $map);


    if ($self->targets) {

	my @view_targets = map { $anchor->subdir($_) } @{$self->targets};
	my @actual_targets = map { $self->root->rename_check($_, $map) }
	    @view_targets;

	my @tmp =  map { $self->source->new( path => $_ ) } @actual_targets;
	my $tmp = shift @tmp;

	unless ($tmp->same_source(@tmp)) {
	    # XXX: be more informative
	    die loc("Can't commit a view with changes in multiple mirror sources.\n");
	}
    }
    else {
	die "view get_editor used without targets";
    }

    my ($editor, $inspector, %extra) = $self->source->new(path => $actual_anchor)->get_editor(%arg);
    # XXX: view has txns, not very happy with forked processes.
    $extra{mirror}->_backend->use_pipeline(0)
        if $extra{mirror} && $extra{mirror}->_backend->isa('SVK::Mirror::Backend::SVNRa');
    my $prefix = abs2rel($self->source->path_anchor,
			 $actual_anchor => undef, '/');

    if (@{$self->view->rename_map2($anchor, $actual_anchor)}) {
	require SVK::Editor::View;
	$editor = SVK::Editor::View->new
	    ( editor => $editor,
	      rename_map => $self->view->rename_map2($anchor, $actual_anchor),
	      prefix => $prefix,
	    );
    }
    $editor = SVN::Delta::Editor->new(_debug => 1, _editor => [$editor])
	if $logger->is_debug();
    return ($editor, $inspector, %extra);
}

sub _recreate_view {
    my $self = shift;
    $self->view((SVK::Command->create_view($self->repos,
					   $self->view->base.'/'.$self->view->name,
					   $self->revision))[1]);
}

sub as_depotpath {
    my ($self, $revision) = @_;
    # return $self->source;
    if (defined $revision) {
	$self = $self->new;
	$self->source->revision($revision);
	$self->revision($revision);
	eval { $self->_recreate_view; } or return undef;
    }
    return $self;
}

sub depotpath {
    my $self = shift;

    return '/'.$self->depotname.$self->view->spec;
}

sub universal { $_[0]->source->universal }

sub normalize {  # SVK::Path normalize is not view safe
    return $_[0];
}

1;
