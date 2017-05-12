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
package SVK::Command::Cmerge;
use strict;
use SVK::Version;  our $VERSION = $SVK::VERSION;

use base qw( SVK::Command::Merge SVK::Command::Copy SVK::Command::Propset );
use SVK::XD;
use SVK::I18N;
use SVK::Logger;
use SVK::Editor::Combine;
use SVK::Inspector::Compat;

sub options {
    ($_[0]->SUPER::options);
}

sub parse_arg {
    my $self = shift;
    $self->SVK::Command::Merge::parse_arg (@_);
}

sub lock {
    my $self = shift;
    $self->SVK::Command::Merge::lock (@_);
}

sub run {
    my ($self, $src, $dst) = @_;
    # XXX: support checkonly
   
    if ($0 =~ /svk$/) { 
        # Only warn about deprecation if the user is running svk. 
        # (Don't warn when running tests)                 
        $logger->warn(loc("%1 cmerge is deprecated, pending improvements to the Subversion API",$0));
        $logger->warn(loc("'Use %1 merge -c' to obtain similar functionality.",$0)."\n");
    }
    my @revlist = $self->parse_revlist($src);
    for my $r (@revlist) {
        die("Revision spec must be N:M.\n") unless defined($r->[1])
    }

    my $repos = $src->repos;
    my $fs = $repos->fs;
    my $base = SVK::Merge->auto (%$self, repos => $repos, src => $src, dst => $dst,
				 ticket => 1)->{base};
    # find a branch target
    die loc("cannot find a path for temporary branch")
	if $base->{path} eq '/';
    my $tmpbranch = "$src->{path}-merge-$$";

    $self->command (copy =>
		    { message => "preparing for cherry picking merging" }
		   )->run ($base => $src->new (path => $tmpbranch))
		       unless $self->{check_only};

    my $ceditor = SVK::Editor::Combine->new(tgt_anchor => $base->{path},
					    #$check_only ? $base_path : $tmpbranch,
					    base_root => $base->root,
					    pool => SVN::Pool->new,
					   );

    my $spool = SVN::Pool->new_default;
    my $inspector = SVK::Inspector::Compat->new({$ceditor->callbacks});
    for (@revlist) {
	my ($fromrev, $torev) = @$_;
	$logger->info(loc("Merging with base %1 %2: applying %3 %4:%5.",
		  @{$base}{qw/path revision/}, $src->{path}, $fromrev, $torev));

	SVK::Merge->new (%$self, repos => $repos,
			 base => $src->new (revision => $fromrev),
			 src => $src->new (revision => $torev), dst => $dst,
			)->run ($ceditor, 
			        inspector => $inspector,
				# XXX: should be base_root's rev?
				cb_rev => sub { $fs->youngest_rev });
	$spool->clear;
    }

    $ceditor->replay (SVN::Delta::Editor->new
		      (_debug => 0,
		       _editor => [ $repos->get_commit_editor
				    ('file://' . $src->depot->repospath,
				     $tmpbranch,
				     $ENV{USER}, "merge $self->{chgspec} from $src->{path}",
				     sub { $logger->info(loc("Committed revision %1.", $_[0])) })
				  ]),
		      $fs->youngest_rev);
    my $newrev = $fs->youngest_rev;
    my $uuid = $fs->get_uuid;

    # give ticket to src
    my $ticket = SVK::Merge->new (xd => $self->{xd})->
	find_merge_sources ($src->new (revision => $newrev), 1, 1);
    $ticket->{"$uuid:$tmpbranch"} = $newrev;

    unless ($self->{check_only}) {
	my $oldmessage = $self->{message};
	$self->{message} = "cherry picking merge $self->{chgspec} to $dst->{path}";
	$self->do_propset_direct ($src, 'svk:merge',
				  join ("\n", map {"$_:$ticket->{$_}"} sort keys %$ticket));
	$self->{message} = $oldmessage;
    }

    my ($depot) = $src->depotname;
    ++$self->{auto};
    undef $self->{chgspec};
    undef $self->{revspec};
    $self->SUPER::run ($src->new (path => $tmpbranch,
				  depotpath => "/$depot$tmpbranch",
				  revision => $fs->youngest_rev),
		       $dst);
    return;
}

1;

__DATA__

=head1 NAME

SVK::Command::Cmerge - Merge specific changes

=head1 SYNOPSIS

 This command is currently deprecated, pending improvements to the
 Subversion API. In the meantime, use C<svk merge -c> to obtain
 similar functionality.

 cmerge -c CHGSPEC DEPOTPATH [PATH]
 cmerge -c CHGSPEC DEPOTPATH1 DEPOTPATH2

=head1 OPTIONS

 -c [--change] REV      : act on comma-separated revisions REV 
 -l [--log]             : use logs of merged revisions as commit message
 -r [--revision] N:M    : act on revisions between N and M
 -a [--auto]            : merge from the previous merge point
 --verbatim             : verbatim merge log without indents and header
 --no-ticket            : do not record this merge point
 -m [--message] MESSAGE : specify commit message MESSAGE
 -F [--file] FILENAME   : read commit message from FILENAME
 --template             : use the specified message as the template to edit
 --encoding ENC         : treat -m/-F value as being in charset encoding ENC
 -P [--patch] NAME      : instead of commit, save this change as a patch
 -S [--sign]            : sign this change
 -C [--check-only]      : try operation but make no changes
 --direct               : commit directly even if the path is mirrored

