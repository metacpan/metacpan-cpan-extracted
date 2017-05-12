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
package SVK::Command::Status;
use strict;
use SVK::Version;  our $VERSION = $SVK::VERSION;

use base qw( SVK::Command );
use constant opt_recursive => 1;
use SVK::XD;
use SVK::Editor::Status;
use SVK::Util qw( abs2rel );
use SVK::Logger;

sub options {
    ("q|quiet"    => 'quiet',
     "no-ignore"  => 'no_ignore',
     "v|verbose"  => 'verbose',
    );
}

sub parse_arg {
    my ($self, @arg) = @_;
    @arg = ('') if $#arg < 0;
    return $self->arg_condensed (@arg);
}

sub _flush_print {
    my ($self, $root, $target, $entry, $status, $baserev, $from_path, $from_rev) = @_;
    my ($crev, $author);
    my $fs = $root->fs;
    if ($from_path) {
	my $repospath = $target->repospath;
	$from_path =~ s{^file://\Q$repospath\E}{};
        $crev = $fs->revision_root ($from_rev)->node_created_rev ($from_path);
	$author = $fs->revision_prop ($crev, 'svn:author');
	$baserev = '-';
    } elsif ($status->[0] =~ '[I?]') {
	$baserev = '';
	$crev = '';
	$author = ' ';
    } elsif ($status->[0] eq 'A') {
	$baserev = 0;
    } elsif ($status->[0] !~ '[!~]') {
        my $p = $target->path_anchor;
	my $path = $p eq '/' ? "/$entry" : (length $entry ? "$p/$entry" : $p);
	$crev = $root->node_created_rev ($path);
	$author = $fs->revision_prop($crev, 'svn:author') unless $crev == -1;
    }

    my $report = $target->report;
    my $newentry = length $entry
	? SVK::Path::Checkout->copath ($report, $entry)
	: SVK::Path::Checkout->copath ('', length $report ? $report : '.');
    no warnings 'uninitialized';
    $logger->info(sprintf ("%1s%1s%1s %8s %8s %-12.12s \%s\n", @{$status}[0..2],
                   defined $baserev ? $baserev : '? ',
		   defined $crev ? $crev : '? ',
		   $author ? $author : ' ?',
                   $newentry));
}

sub run {
    my ($self, $target) = @_;
    my $editor = SVK::Editor::Status->new (
	  ignore_absent => $self->{quiet},
	  $self->{verbose} ?
	  (notify => SVK::Notify->new (
	       flush_baserev => 1,
	       flush_unchanged => 1,
	       cb_flush => sub { _flush_print ($self, $target->root, $target, @_); }
	   )
	  )                :
	  (notify => SVK::Notify->new_with_report ($target->report,
		undef, 1)
	  )
      );
    $self->{xd}->checkout_delta
	( $target->for_checkout_delta,
	  xdroot => $target->create_xd_root,
	  nodelay => 1,
	  delete_verbose => 1,
	  editor => $editor,
	  cb_conflict => sub { shift->conflict(@_) },
	  cb_obstruct => sub { shift->obstruct(@_) },
	  $self->{verbose} ?
	      (cb_unchanged => sub { shift->unchanged(@_) },
	      )            :
	      (),
	  $self->{recursive} ? () : (depth => 1),
	  $self->{no_ignore} ?
              (cb_ignored => sub { shift->ignored(@_) },
              )              :
              (),
	  $self->{quiet} ?
              ()         :
              (cb_unknown => sub { shift->unknown(@_) } )
	);
    return;
}

1;

__DATA__

=head1 NAME

SVK::Command::Status - Display the status of items in the checkout copy

=head1 SYNOPSIS

 status [PATH..]

=head1 OPTIONS

 -q [--quiet]           : do not display files not under version control
 --no-ignore            : disregard default and svn:ignore property ignores
 -N [--non-recursive]   : do not descend recursively
 -v [--verbose]         : print full revision information on every item

=head1 DESCRIPTION

Show pending changes in the checkout copy.

The first three columns in the output are each one character wide:

First column, says if item was added, deleted, or otherwise changed:

  ' '  no modifications
  'A' Added
  'C' Conflicted
  'D' Deleted
  'I' Ignored
  'M' Modified
  'R' Replaced
  '?' item is not under version control
  '!' item is missing (removed by non-svk command) or incomplete
  '~' versioned item obstructed by some item of a different kind

Second column, modifications of a file's or directory's properties:

  ' ' no modifications
  'C' Conflicted
  'M' Modified

Third column, scheduled commit will contain addition-with-history

  ' ' no history scheduled with commit
  '+' history scheduled with commit

Remaining fields are variable width and delimited by spaces:
  The working revision (with -v)
  The last committed revision and last committed author (with -v)
  The working copy path is always the final field, so it can include spaces.

Example output:

  svk status
   M  bar.c
  A + qax.c

  svk status --verbose wc
   M        53        2 sally        wc/bar.c
            53       51 harry        wc/foo.c
  A +        -       ?   ?           wc/qax.c
            53       43 harry        wc/zig.c
            53       20 sally        wc

