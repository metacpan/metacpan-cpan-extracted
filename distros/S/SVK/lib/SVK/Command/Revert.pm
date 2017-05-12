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
package SVK::Command::Revert;
use strict;
use SVK::Version;  our $VERSION = $SVK::VERSION;

use base qw( SVK::Command );
use constant opt_recursive => 0;
use SVK::XD;
use SVK::Util qw( slurp_fh is_symlink to_native );
use SVK::I18N;
use SVK::Logger;

sub options {
    ("q|quiet"    => 'quiet');
}

sub parse_arg {
    my $self = shift;
    my @arg = @_;
    @arg = ('') if $#arg < 0;

    return $self->arg_condensed(@arg);
}

sub lock {
    $_[0]->lock_target ($_[1]);
}

sub run {
    my ($self, $target) = @_;
    my $xdroot = $target->create_xd_root;

    my @replaced;
	$self->{xd}->checkout_delta
	    ( $target->for_checkout_delta,
	      xdroot => $xdroot,
	      depth => $self->{recursive} ? undef : 0,
	      delete_verbose => 1,
	      absent_verbose => 1,
	      nodelay => 1,
	      cb_conflict => sub { shift->conflict(@_) },
	      cb_unknown => sub { shift->unknown(@_) },
	      editor => SVK::Editor::Status->new
	      ( notify => SVK::Notify->new
		( cb_flush => sub {
		      my ($path, $status) = @_;
		      my $st = $status->[0];
                      push @replaced, $path if $st eq 'R';
		      my $dpath = length $path ? $target->path_anchor."/$path" : $target->path_anchor;
	              to_native($path);
		      my $copath = $target->copath ($path);
                      if ($st =~ /[DMRC!]/) {
			  # conflicted items do not necessarily exist
			  return $self->do_unschedule ($target, $copath)
			      if ($st eq 'C' || $status->[2]) && !$xdroot->check_path ($dpath);
                          return $self->do_revert($target, $copath, $dpath, $xdroot);
                      } elsif ($st eq '?') {
			  return unless $target->contains_copath ($copath);
			  $logger->warn(loc("%1 is not versioned; ignored.",
			      $target->report_copath ($copath)));
			  return;
		      }

		      # Check that we are not reverting parents
		      $target->contains_copath($copath) or return;

                      $self->do_unschedule($target, $copath);
		  },
		),
	      ));

    if (@replaced) {
        $target->source->targets(\@replaced);
        $self->run($target);
    }

    return;
}

sub do_revert {
    my ($self, $target, $copath, $dpath, $xdroot) = @_;

    # XXX: need to respect copied resources
    my $kind = $xdroot->check_path ($dpath);
    if ($kind == $SVN::Node::dir) {
        unless (-e $copath) {
	    mkdir $copath or die loc("Can't create directory while trying to revert %1.\n", $copath);
        }
    }
    else {
	# XXX: PerlIO::via::symlink should take care of this.
	# It doesn't overwrite existing file or close.
	unlink $copath;
	my $fh = SVK::XD::get_fh ($xdroot, '>', $dpath, $copath) or die loc("Can't create file while trying to revert %1.\n", $copath);
	my $content = $xdroot->file_contents ($dpath);
	slurp_fh ($content, $fh);
	close $fh or die $!;
	# XXX: get_fh should open file with proper permission bit
	$self->{xd}->fix_permission ($copath, 1)
	    if defined $xdroot->node_prop ($dpath, 'svn:executable');
    }
    $self->do_unschedule($target, $copath);
}

sub do_unschedule {
    my ($self, $target, $copath) = @_;
    $self->{xd}{checkout}->store($copath, { $self->_schedule_empty,
					    '.conflict' => undef }, {override_descendents => 0});
    $logger->info(loc("Reverted %1", $target->report_copath ($copath)))
	unless $self->{quiet};

}

1;

__DATA__

=head1 NAME

SVK::Command::Revert - Revert changes made in checkout copies

=head1 SYNOPSIS

 revert PATH...

=head1 OPTIONS

 -R [--recursive]       : descend recursively
 -q [--quiet]           : print as little as possible


