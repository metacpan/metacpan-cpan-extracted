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
package SVK::Command::Delete;
use strict;
use SVK::Version;  our $VERSION = $SVK::VERSION;
use base qw( SVK::Command::Commit );
use SVK::XD;
use SVK::I18N;
use SVK::Util qw( abs2rel );

sub options {
    ($_[0]->SUPER::options,
     'force'	=> 'force',
     'K|keep-local'	=> 'keep');
}

sub parse_arg {
    my ($self, @arg) = @_;
    return if $#arg < 0;
    my $target;
    @arg = map { $self->{xd}->target_from_copath_maybe($_) } @arg;

    # XXX: better check for @target being the same type
    if (grep {$_->isa('SVK::Path::Checkout')} @arg) {
	die loc("Mixed depotpath and checkoutpath not supported.\n")
	    if grep {!$_->isa('SVK::Path::Checkout')} @arg;

	return $self->{xd}->target_condensed(@arg);
    }

    return @arg;
}

sub lock {
    my ($self, $target) = @_;
    $self->lock_target ($target);
}

sub do_delete_direct {
    my ( $self, @args ) = @_;
    my $target = $args[0];
    my $m      = $self->under_mirror($target);
    if ( $m && $m->path eq $target->path ) {
        $m->detach;
        $target->refresh_revision;
        undef $m;
    }

    $self->get_commit_message;
    $target->normalize;
    $target->refresh_revision;
    my ( $anchor, $editor ) = $self->get_dynamic_editor($target);
    for (@args) {
        $editor->delete_entry( abs2rel( $_->path, $anchor => undef, '/' ),
            $target->revision, 0 );
        $self->adjust_anchor($editor);
    }
    $self->finalize_dynamic_editor($editor);
}

sub _ensure_mirror {
    my ($self, $target) = @_;

    my @m = $target->contains_mirror or return;

    return if $#m == 0 && $m[0] eq $target->path_anchor;

    my $depotname = $target->depotname;
    die loc("%1 contains mirror, remove explicitly: ", "/$depotname".$target->path_anchor).
	join(',', map { "/$depotname$_" } @m)."\n"
}

sub run {
    my ($self, @args) = @_;


    if ($args[0]->isa('SVK::Path::Checkout')) {
	my $target = $args[0]; # already condensed
	$self->_ensure_mirror($target);
	$self->{xd}->do_delete( $target, no_rm => $self->{keep}, 
		'force_delete' => $self->{force} );
    }
    else {
	$self->_ensure_mirror($_) for @args;
	die loc("Different source.\n") unless
	    $args[0]->same_source(@args);
	$self->do_delete_direct( @args );
    }

    return;
}

1;

__DATA__

=head1 NAME

SVK::Command::Delete - Remove versioned item

=head1 SYNOPSIS

 delete [PATH...]
 delete [DEPOTPATH...]

=head1 OPTIONS

 -K [--keep-local]      : do not remove the local file
 -m [--message] MESSAGE : specify commit message MESSAGE
 -F [--file] FILENAME   : read commit message from FILENAME
 --template             : use the specified message as the template to edit
 --encoding ENC         : treat -m/-F value as being in charset encoding ENC
 -P [--patch] NAME      : instead of commit, save this change as a patch
 -S [--sign]            : sign this change
 -C [--check-only]      : try operation but make no changes
 --direct               : commit directly even if the path is mirrored
 --force                : delete the file/directory even if modified

