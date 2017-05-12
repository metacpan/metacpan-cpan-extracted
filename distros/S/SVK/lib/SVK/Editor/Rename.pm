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
package SVK::Editor::Rename;
use strict;
use SVK::Version;  our $VERSION = $SVK::VERSION;
use base qw(SVK::Editor::Patch);
use SVK::I18N;
use SVK::Util 'is_path_inside';

=head1 NAME

SVK::Editor::Rename - An editor that translates editor calls for renamed entries

=head1 SYNOPSIS

  $editor = SVK::Editor::Rename->new
    ( editor => $next_editor,
      rename_map => \@rename_map
    );

=head1 DESCRIPTION

Given the rename_map, which is a list of [from, to] pairs for
translating path in editor calls, C<SVK::Editor::Rename> serialize the
calls and rearrange them for making proper calls to C<$next_editor>.

The translation of pathnames is done with iterating through the
C<@rename_map>, translate with the first match. Translation is redone
untill no match is found.

C<SVK::Editor::Rename> is a subclass of C<SVK::Editor::Patch>, which
serailizes incoming editor calls. Each baton opened is recorded in
C<$self->{opened_baton}>, which could be use to lookup with path names.

When a path is opened that should be renamed, it's recorded in
C<$self->{renamed_anchor}> for reanchoring the renamed result to
proper parent directory before calls are emitted to C<$next_editor>.

=cut

sub rename_check {
    my ($self, $path, $nocache) = @_;
    return $self->{rename_cache}{$path}
	if exists $self->{rename_cache}{$path};
    for (@{$self->{rename_map}}) {
	my ($from, $to) = @$_;
	if (is_path_inside($path, $from)) {
	    my $newpath = $path;
	    $newpath =~ s/^\Q$from\E/$to/;
	    $newpath = $self->rename_check ($newpath, 1);
	    $self->{rename_cache}{$path} = $newpath;
	    return $newpath;
	}
    }
    return $path;
}

sub _same_parent {
    my ($path1, $path2) = @_;
    $path1 =~ s|/[^/]*$|/|;
    $path2 =~ s|/[^/]*$|/|;
    return $path1 eq $path2;
}

sub open_root {
    my ($self, @arg) = @_;
    my $ret = $self->SUPER::open_root (@arg);
    $self->{opened_baton}{''} = [$ret, 0];
    return $ret;
}

sub AUTOLOAD {
    my ($self, @arg) = @_;
    my $func = our $AUTOLOAD;
    my $class = ref ($self);
    $func =~ s/^.*:://;
    return if $func =~ m/^[A-Z]+$/;
    my $baton_at = $self->baton_at ($func);
    my ($renamed, $renamed_anchor);
    if ($baton_at > 0) {
	my $newpath = $self->rename_check ($arg[0]);
	if ($newpath ne $arg[0]) {
	    ++$renamed;
	    # XXX: always reanchor for now. skip those non-leaf matching.
	    # 'mv A/file A/B/file; mv A/B A/C'
	    # tracking the change made on file would die on opening 'B'
#	    if (exists $self->{renamed}[$arg[1]]) {
#	    }
#	    else {
		++$renamed_anchor unless _same_parent ($newpath, $arg[0]);
#	    }
	    $arg[0] = $newpath;
	}
    }

    my $sfunc = "SUPER::$func";
    my $ret = $self->$sfunc (@arg);

    $self->{renamed}[$ret]++ if $renamed && $ret;

    if ($renamed_anchor) {
	push @{$self->{renamed_anchor}}, $self->{edit_tree}[$arg[$baton_at]][-1];
    }
    else {
	$self->{opened_baton}{$arg[0]} = [$ret, $arg[1]]
	    if $func =~ m/^open/;
    }

    return $ret;
}

sub open_parent {
    my ($self, $path) = @_;
    my $parent = $path;
    $parent =~ s|/[^/]*$|| or $parent = '';
    return @{$self->{opened_baton}{$parent}}
	if exists $self->{opened_baton}{$parent};

    my ($pbaton, $ppbaton) = $self->open_parent ($parent);

    ++$self->{batons};

    # XXX: If inspector is always there, then the first check isn't necessary.
    if ($self->{inspector} && !$self->{inspector}->exist($parent)) {
	unshift @{$self->{edit_tree}[$pbaton]},
	    [$self->{batons}, 'add_directory', $parent, $ppbaton, undef, -1];
    }
    else {
	unshift @{$self->{edit_tree}[$pbaton]},
	    [$self->{batons}, 'open_directory', $parent, $ppbaton, -1];
    }

    $self->{edit_tree}[$self->{batons}] = [[undef, 'close_directory', $self->{batons}]];
    $self->{opened_baton}{$parent} = [$self->{batons}, $pbaton];
    return ($self->{batons}, $pbaton);
}

sub adjust_anchor {
    my ($self, $entry) = @_;
    my $path = $entry->[2];
    my ($pbaton) = $self->open_parent ($path);
    my @newentry = @$entry;
    $self->_insert_entry ($self->{edit_tree}[$pbaton] ||= [], \@newentry);
    $newentry[2+$self->baton_at ($entry->[1])] = $pbaton;
    @$entry = [];
}

sub adjust_last_anchor {
    $_[0]->adjust_anchor($_[0]{edit_tree}[0][-1]);
}

sub _insert_entry {
    my ($self, $anchor, $entry) = @_;
    # move the call to a proper place.
    # retain the order, but calls must be placed before close.
    if (@$anchor && $anchor->[-1][1] =~ m/^close/) {
	splice @$anchor, -1, 0, $entry;
    }
    else {
	push @$anchor, $entry;
    }
}

sub close_edit {
    my $self = shift;
    $self->SUPER::close_edit (@_);
    for (@{$self->{renamed_anchor}}) {
	$self->adjust_anchor($_);
    }
    # XXX: addition phase here to trim useless opens.
    $self->drive ($self->{editor});
#SVN::Delta::Editor->new (_debug => 1, _editor => [$self->{editor}]));
}

# Make sure driven editor aborts too.
sub abort_edit {
    my $self = shift;
    $self->SUPER::abort_edit (@_);
    my $r = $self->{editor}->abort_edit(@_);
    return $r;
}


1;
