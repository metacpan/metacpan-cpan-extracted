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
package SVK::Editor::Patch;
use strict;
use SVK::Version;  our $VERSION = $SVK::VERSION;

require SVN::Delta;
use base 'SVK::Editor';

=head1 NAME

SVK::Editor::Patch - An editor to serialize editor calls.

=head1 SYNOPSIS

    $patch = SVK::Editor::Patch->new...
    # feed things to $patch
    $patch->drive ($editor);

=head1 DESCRIPTION

C<SVK::Editor::Patch> serializes incoming editor calls in a tree
structure. C<$editor->{edit_tree}> is an array indexed by the baton id
of directories. The value of each entry is an array of editor calls
that have baton id as parent directory. Each entry of editor calls is
an array with the first element being the child baton id (if any), and
then the method name and its arguments.

=cut

sub AUTOLOAD {
    my ($self, @arg) = @_;
    my $func = our $AUTOLOAD;
    $func =~ s/^.*:://;
    return if $func =~ m/^[A-Z]+$/;
    my $baton;

    pop @arg if ref ($arg[-1]) =~ m/^(?:SVN::Pool|_p_apr_pool_t)$/;

    if ((my $baton_at = $self->baton_at ($func)) >= 0) {
	$baton = $arg[$baton_at];
    }
    else {
	$baton = 0;
    }

    my $ret = $func =~ m/^(?:add|open)/ ? ++$self->{batons} : undef;
    Carp::cluck unless defined $func;
    push @{$self->{edit_tree}[$baton]}, [$ret, $func, @arg];
    return $ret;
}

sub apply_textdelta {
    my ($self, $baton, @arg) = @_;
    pop @arg if ref ($arg[-1]) =~ m/^(?:SVN::Pool|_p_apr_pool_t)$/;
    push @{$self->{edit_tree}[$baton]}, [undef, 'apply_textdelta', $baton, @arg, ''];
    open my ($svndiff), '>', \$self->{edit_tree}[$baton][-1][-1];
    return [SVN::TxDelta::to_svndiff ($svndiff)];
}

sub emit {
    my ($self, $editor, $func, $pool, @arg) = @_;
    my ($ret, $baton_at);
    if ($func eq 'apply_textdelta') {
#	$pool->default;
	my $svndiff = pop @arg;
	$ret = $editor->apply_textdelta (@arg, $pool);
	if ($ret && $#$ret > 0) {
	    my $stream = SVN::TxDelta::parse_svndiff (@$ret, 1, $pool);
	    print $stream $svndiff;
	    close $stream;
	}
    }
    else {
	$ret = $editor->$func (@arg, $pool);
    }
    return $ret;
}

sub drive {
    my ($self, $editor, $calls, $baton) = @_;
    $calls ||= $self->{edit_tree}[0];
    # XXX: Editor::Merge calls $pool->default, which is unhappy with svn::pool objects.
    my $pool = SVN::Pool::create (undef);
    for my $entry (@$calls) {
	my ($next, $func, @arg) = @$entry;
	next unless $func;
	my ($ret, $baton_at);
	$arg[$baton_at] = $baton
	    if ($baton_at = $self->baton_at ($func)) >= 0;

	$ret = $self->emit ($editor, $func, $pool, @arg);

	$self->drive ($editor, $self->{edit_tree}[$next], $ret)
	    if $next;
    }
    SVN::Pool::apr_pool_destroy ($pool);
}


1;
