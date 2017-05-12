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
package SVK::Command::Log;
use strict;
use SVK::Version;  our $VERSION = $SVK::VERSION;

use base qw( SVK::Command );
use SVK::XD;
use SVK::I18N;
use SVK::Util qw( traverse_history get_encoding reformat_svn_date can_run );
use List::Util qw(max min);
use SVK::Logger;

sub options {
    (
        'l|limit=i'	    => 'limit',
        'q|quiet'		=> 'quiet',
        'r|revision=s@'	=> 'revspec',
        'x|cross'		=> 'cross',
        'v|verbose'	    => 'verbose',
        'xml'           => 'xml',
        'output:s'      => 'present_filter',
        'filter:s'      => 'select_filter',
    );
}

# returns a sub for getting remote rev
sub _log_remote_rev {
    my ( $target, $remoteonly ) = @_;

    # don't bother if this repository has no mirror
    return unless $target->mirror->entries;

    # we might be running log on a path containing mirrors.
    # FIXME: resolve when log outside mirror anchor
    my $m = $target->is_mirrored;
    return sub { my $prop = $target->repos->fs->revision_prop($_[0], 'svm:headrev') or return;
		 my %rev = map {split (':', $_, 2)} $prop =~ m/^.*$/mg;
		 return (values %rev)[0];
	     } unless $m;
    return sub {
        my $rrev = $m->find_remote_rev( $_[0], $target->repos );
        return $rrev;
    }
}

sub parse_arg {
    my $self = shift;
    my @arg = @_;
    @arg = ('') if $#arg < 0;

    return $self->arg_co_maybe (@arg);
}

sub run {
    my ($self, $target) = @_;
    # as_depotpath, but use the base revision rather than youngest
    # for the target.

    # establish the output argument (presentation filter)
    my ( $presentation_filter, $filter_xml ) = @{$self}{qw/present_filter xml/};
    if ($filter_xml) {
        $logger->warn(loc("Ignoring --output $presentation_filter. Using --xml."))
            if $presentation_filter;
        $presentation_filter = 'xml';
    }
    else {
        $presentation_filter ||= $ENV{SVKLOGOUTPUT} || 'Std';
    }

    my ($fromrev, $torev);
    # move to general revspec parser in svk::command
    if (defined $self->{revspec}) {
        ($fromrev, $torev) = $self->resolve_revspec($target);
	$torev ||= $fromrev;
    }
    $target = $target->as_depotpath($self->find_base_rev($target))
	if $target->isa('SVK::Path::Checkout');
    $fromrev = $target->revision unless defined $fromrev;
    $torev = 0 unless defined $torev;
    $self->{cross} ||= 0;

    my $get_remoterev = _log_remote_rev($target);

    if ($target->revision < max ($fromrev, $torev)) {
	$logger->warn(loc ("Revision too large, show log from %1.", $target->revision));
	$fromrev = min ($target->revision, $fromrev);
	$torev = min ($target->revision, $torev);
    }

    my $select_filter = $self->{select_filter};
    if (defined $self->{limit}) {
        $select_filter .= ' | ' if defined $select_filter and length $select_filter;
        $select_filter .= "head " . $self->{limit};
    }
    require SVK::Log::FilterPipeline;
    my $pipeline = SVK::Log::FilterPipeline->new(
        presentation  => $presentation_filter,
        selection     => $select_filter,
        output        => undef,
        indent        => 0,
        get_remoterev => $get_remoterev,
        verbatim      => 0,
        quiet         => $self->{quiet},
        verbose       => $self->{verbose},
    );

    if($ENV{SVKPAGER} && can_run($ENV{SVKPAGER})){
        eval '$ENV{PAGER}=$ENV{SVKPAGER};use IO::Pager;IO::Pager->new(*STDOUT)';
    }

    _get_logs(
        root     => $target->root,
        path     => $target->path_anchor,
        fromrev  => $fromrev,
        torev    => $torev,
        verbose  => $self->{verbose},
        cross    => $self->{cross},
        pipeline => $pipeline,
    );
    return;
}

sub _get_logs {
    my (%args) = @_;
    my   (   $root, $path, $fromrev, $torev, $cross, $pipeline, $cb_log) = 
    @args{qw/ root   path   fromrev   torev   cross   pipeline   cb_log/};

    my $fs = $root->fs;
    my $reverse = ($fromrev < $torev);
    my @revs;
    ($fromrev, $torev) = ($torev, $fromrev) if $reverse;
    $torev = 1 if $torev < 1;

    # establish the traverse_history callback
    my $docall;
    if ($pipeline) {
        $docall = sub {
            my ($rev) = @_;
            my $root  = $fs->revision_root($rev);
            my $props = $fs->revision_proplist($rev);
            return $pipeline->filter(    # only continue if $pipeline wants to
                rev   => $rev,
                root  => $root,
                props => $props,
            );
        };
    }
    else {
        $docall = sub {
            my ($rev) = @_;
            my $root  = $fs->revision_root($rev);
            my $props = $fs->revision_proplist($rev);
            $cb_log->( $rev, $root, $props );
            return 1;  # always continue to the next revision
        };
    }

    traverse_history (
        root        => $root,
        path        => $path,
        cross       => $cross,
        callback    => sub {
            my $rev = $_[1];
            return 1 if $rev > $fromrev; # next
            return 0 if $rev < $torev;   # last

            if ($reverse) {
                unshift @revs, $rev;
                return 1;
            }
            return $docall->($rev);
        },
    );

    if ($reverse) {
	my $pool = SVN::Pool->new_default;
	$docall->($_), $pool->clear for @revs;
    }

    # we're done with the log so we're done with the pipeline
    $pipeline->finished() if $pipeline;
}

our $chg;
require SVN::Fs;
$chg->[$SVN::Fs::PathChange::modify] = 'M';
$chg->[$SVN::Fs::PathChange::add] = 'A';
$chg->[$SVN::Fs::PathChange::delete] = 'D';
$chg->[$SVN::Fs::PathChange::replace] = 'R';

sub do_log {
    my (%arg) = @_;
    my (    $cross, $fromrev, $path, $repos, $torev, $pipeline, $cb_log ) =
    @arg{qw/ cross   fromrev   path   repos   torev   pipeline   cb_log /};

    $cross ||= 0;
    my $pool = SVN::Pool->new_default;
    my $fs = $repos->fs;
    my $rev = $fromrev > $torev ? $fromrev : $torev;
    _get_logs (
        root     => $fs->revision_root($rev),
        path     => $path,
        fromrev  => $fromrev,
        torev    => $torev,
        cross    => $cross,
        pipeline => $pipeline,  # let _get_logs() sort out the pipeline ...
        cb_log   => $cb_log,    # ... vs cb_log  (only 1 should be defined)
    );
}

1;

__DATA__

=head1 NAME

SVK::Command::Log - Show log messages for revisions

=head1 SYNOPSIS

 log DEPOTPATH
 log PATH
 log -r N[:M] [DEPOT]PATH

=head1 OPTIONS

 -r [--revision] ARG      : ARG (some commands also take ARG1:ARG2 range)

                          A revision argument can be one of:

                          "HEAD"       latest in repository
                          {DATE}       revision at start of the date
                          NUMBER       revision number
                          NUMBER@      interpret as remote revision number
                          NUM1:NUM2    revision range

                          Unlike other commands,  negative NUMBER has no
                          meaning.

 -l [--limit] REV       : stop after displaying REV revisions
 -q [--quiet]           : Don't display the actual log message itself
 -x [--cross]           : track revisions copied from elsewhere
 -v [--verbose]         : print extra information
    --xml               : display the log messages in XML format
    --filter FILTER     : select revisions based on FILTER
    --output FILTER     : display logs using the given FILTER

=head1 DESCRIPTION

Display the log messages and other meta-data associated with revisions.

SVK provides a flexible system allowing log messages and other revision
properties to be displayed and processed in many ways.  This flexibility comes
through the use of "log filters."  Log filters are of two types: selection and
output.  Selection filters determine which revisions are included in the
output, while output filters determine how the information about those
revisions is displayed.  Here's a simple example.  These two invocations
produce equivalent output:

    svk log -l 5 //local/project
    svk log --filter "head 5" --output std //local/project

The "head" filter chooses only the first revisions that it encounters, in this
case, the first 5 revisions.  The "std" filter displays the revisions using
SVK's default output format.

Selection filters can be connected together into pipelines.  For example, to
see the first 3 revisions with log messages containing the string 'needle', we
might do this

    svk log --filter "grep needle | head 3" //local/project

That example introduced the "grep" filter.  The argument for the grep filter
is a valid Perl pattern (with any '|' characters as '\|' and '\' as '\\').  A
revision is allowed to continue to the next stage of the pipeline if the
revision's log message matches the pattern.  If we wanted to search only the
first 10 revisions for 'needle' we could use either of the following commands

    svk log --filter "head 10 | grep needle" //local/project
    svk log -l 10 --filter "grep needle" //local/project

You may change SVK's default output filter by setting the SVKLOGOUTPUT
environment.  See B<svk help environment> for details.

=head2 Standard Filters

The following log filters are included with the standard SVK
distribution:

    Selection : grep, head, author
    Output    : std, xml

For detailed documentation about any of these filters, try "perldoc
SVK::Log::Filter::Name" where "Name" is "Grep", "Head", "XML", etc.. Other log
filters are available from CPAN L<http://search.cpan.org> by searching for
"SVK::Log::Filter".  For details on writing log filters, see the documentation
for the SVK::Log::Filter module.

