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
package SVK::Command::Diff;
use strict;
use SVK::Version;  our $VERSION = $SVK::VERSION;

use base qw( SVK::Command );
use constant opt_recursive => 1;
use SVK::I18N;
use autouse 'SVK::Util' => qw(get_anchor);

sub options {
    ("v|verbose"    => 'verbose',
     "s|summarize"  => 'summarize',
     "X|expand"     => 'expand',
     "r|revision=s@" => 'revspec',
     # *not* using chgspec, which does comma-separated stuff
     "c|change=s"    => 'change',
    );
}

sub parse_arg {
    my ($self, @arg) = @_;
    @arg = ('') if $#arg < 0;
    return map {$self->arg_co_maybe ($_)} @arg;
}

# XXX: need to handle peg revisions, ie
# -r N PATH@M means the node PATH@M at rev N
sub run {
    my ($self, $target, $target2) = @_;
    my $fs = $target->repos->fs;
    my $yrev = $fs->youngest_rev;
    my ($cb_llabel, $report);
    my ($r1, $r2) = $self->resolve_revspec($target,$target2);
    my $oldroot;
    # translate to target and target2
    if ($target2) {
	if ($target->isa('SVK::Path::Checkout')) {
	    die loc("Invalid arguments.\n")
		unless $target2->isa('SVK::Path::Checkout');
            $self->run($_) foreach @_[1..$#_];
            return;
	}
	if ($target2->isa('SVK::Path::Checkout')) {
	    die loc("Invalid arguments.\n")
		if $target->isa('SVK::Path::Checkout');
	    $target = $target->new(revision => $r1) if $r1;
	    # diff DEPOTPATH COPATH require DEPOTPATH to exist
	    die loc("path %1 does not exist.\n", $target->report)
		if $target->root->check_path ($target->path_anchor) == $SVN::Node::none;
	}
    }
    else {
	if ($target->isa('SVK::Path::Checkout')) {
	    $target2 = $target->new;
	    $report = $target->report; # get the report before it turns to depotpath
	    $target = $target->as_depotpath;
	    $target = $target->seek_to($r1) if defined $r1;
	    $target2 = $target->as_depotpath->seek_to($r2) if $r2;
	    # if no revision is specified, use the xdroot as target1's root
	    $oldroot = $target2->create_xd_root unless $r1 || $r2;
	    $cb_llabel =
		sub { my ($rpath) = @_;
		      'revision '.($self->{xd}{checkout}->get ($target2->copath ($rpath))->{revision}) } unless $r1;
	}
	else {
	    die loc("Revision required.\n") unless $r1 && $r2;
	    ($target, $target2) = map { $target->as_depotpath->seek_to($_) }
		($r1, $r2);
	}
    }

    unless ($target2->isa('SVK::Path::Checkout')) {
	die loc("path %1 does not exist.\n", $target2->report)
	    if $target2->root->check_path($target2->path_anchor) == $SVN::Node::none;
    }

    my $editor = $self->{summarize} ?
	SVK::Editor::Status->new
	: SVK::Editor::Diff->new
	( $cb_llabel ? (cb_llabel => $cb_llabel) : (llabel => "revision ".($target->revision)),
	  rlabel => $target2->isa('SVK::Path::Checkout')
	           ? 'local' : "revision ".($target2->revision),
	  external => $ENV{SVKDIFF},
	  $target->path_anchor ne $target2->path_anchor ?
	  ( lpath  => $target->path_anchor,
	    rpath  => $target2->path_anchor ) : (),
	  base_target => $target, base_root => $target->root,
	);

    $oldroot ||= $target->root;
    if ($target2->isa('SVK::Path::Checkout')) {
	while ($oldroot->check_path($target->path_anchor) != $SVN::Node::dir) {
	    $target2->anchorify;
	    $target->anchorify;
	    ($report) = get_anchor (0, $report) if defined $report;
	}
	$editor->{report} = $report;
	$self->{xd}->checkout_delta
	    ( $target2->for_checkout_delta,
	      $self->{expand}
	      ? ( expand_copy => 1 )
	      : ( cb_copyfrom => sub { @_ } ),
	      base_root => $oldroot,
	      base_path => $target->path_anchor,
	      xdroot => $target2->create_xd_root,
	      editor => $editor,
	      $self->{recursive} ? () : (depth => 1),
	    );
    }
    else {
        my $kind = $oldroot->check_path($target->path_anchor);
	die loc("path %1 does not exist.\n", $target->report)
	    if $kind == $SVN::Node::none;

	if ($kind != $SVN::Node::dir) {
	    $target->anchorify;
	    ($report) = get_anchor (0, $report) if defined $report;
	    $target2->anchorify;
	}
	$editor->{report} = $report;

	require SVK::Editor::Copy;
	require SVK::Merge;
	$editor = SVK::Editor::Copy->new
	    ( _editor => [$editor],
	      base_root => $target->root,
	      base_path => $target->path,
	      base_rev => $target->revision,
	      copyboundry_rev => $target->revision,
	      copyboundry_root => $target->root,
	      merge => SVK::Merge->new( xd => $self->{xd}, repos => $target->repos ), # XXX: hack
	      base => $target,
	      src => $target2,
	      dst => $target2,
	      cb_resolve_copy => sub {
		  my (undef, undef, $cp_path, $cp_rev) = @_;
		  return ($cp_path, $cp_rev);
	      }) unless $self->{expand};

	$self->{xd}->depot_delta
	    ( oldroot => $oldroot,
	      oldpath => [$target->path_anchor, $target->path_target],
	      newroot => $target2->root,
	      newpath => $target2->path,
	      editor => $editor,
	      $self->{recursive} ? () : (no_recurse => 1),
	    );
    }

    return;
}

1;

__DATA__

=head1 NAME

SVK::Command::Diff - Display diff between revisions or checkout copies

=head1 SYNOPSIS

 diff [-r REV] [PATH...]
 diff -r N[:M] DEPOTPATH
 diff -c N DEPOTPATH
 diff DEPOTPATH1 DEPOTPATH2
 diff DEPOTPATH PATH

=head1 OPTIONS

 -r [--revision] arg    : ARG (some commands also take ARG1:ARG2 range)
 -c [--change]   rev    : show change from rev-1 to rev (reverse if negative)

                          A revision argument can be one of:

                          "HEAD"       latest in repository
                          {DATE}       revision at start of the date
                          NUMBER       revision number
                          NUMBER@      interpret as remote revision number
                          NUM1:NUM2    revision range

                          Given negative NUMBER means "HEAD"+NUMBER.
                          (Counting backwards)

 -s [--summarize]       : show summary only
 -v [--verbose]         : print extra information
 -X [--expand]          : expand files copied as new files
 -N [--non-recursive]   : do not descend recursively

 See also SVKDIFF in svk help environment.

