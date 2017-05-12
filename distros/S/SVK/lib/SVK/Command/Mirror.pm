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
package SVK::Command::Mirror;
use strict;
use SVK::Version;  our $VERSION = $SVK::VERSION;

use base qw( SVK::Command::Commit );
use SVK::I18N;
use SVK::Util qw( is_uri get_prompt traverse_history );
use SVK::Logger;

use constant narg => undef;

sub options {
    ('l|list'  => 'list',
     'd|delete|detach'=> 'detach',
     'b|bootstrap=s' => 'bootstrap',
     'upgrade' => 'upgrade',
     'relocate'=> 'relocate',
     'unlock'=> 'unlock',
     'recover'=> 'recover');
}

sub lock {} # override commit's locking

sub parse_arg {
    my ($self, @arg) = @_;

    @arg = ('//') if $self->{upgrade} and !@arg;
    return if !@arg;

    my $path = shift(@arg);

    # Allow "svk mi uri://... //depot" to mean "svk mi //depot uri://"
    if (is_uri($path) && $arg[0]) {
        ($arg[0], $path) = ($path, $arg[0]);
    }

    if (defined (my $narg = $self->narg)) {
        return unless $narg == (scalar @arg + 1);
    }

    return ($self->arg_depotpath ($path), @arg);
}

sub run {
    my ( $self, $target, $source, @options ) = @_;

    SVK::Mirror->create(
        {
            depot   => $target->depot,
            path    => $target->path,
            backend => 'SVNRa',
            url     => "$source", # this can be an URI object
            pool    => SVN::Pool->new
        }
    );

    $logger->info( loc("Mirror initialized.  Run svk sync %1 to start mirroring.\n", $target->report));

    return;
}

package SVK::Command::Mirror::relocate;
use SVK::Logger;
use base qw(SVK::Command::Mirror);
use SVK::I18N;

sub run {
    my ($self, $target, $source, @options) = @_;

    my ($m, $mpath) = $target->is_mirrored;

    die loc("%1 is not a mirrored path.\n", $target->depotpath) if !$m;
    die loc("%1 is inside a mirrored path.\n", $target->depotpath) if $mpath;

    $m->relocate($source, @options);

    $logger->info( loc("Mirror relocated."));
    return;
}

package SVK::Command::Mirror::detach;
use base qw(SVK::Command::Mirror);
use SVK::I18N;

use SVK::Logger;
use constant narg => 1;

sub run {
    my ($self, $target) = @_;
    my ($m, $mpath) = $target->is_mirrored;

    die loc("%1 is not a mirrored path.\n", $target->depotpath) if !$m;
    die loc("%1 is inside a mirrored path.\n", $target->depotpath) if $mpath;

    $m->detach(1); # remove svm:source and svm:uuid too
    $logger->info( loc("Mirror path '%1' detached.\n", $target->depotpath));
    return;
}

package SVK::Command::Mirror::bootstrap;
use base qw(SVK::Command::Mirror);
use SVK::I18N;
use SVK::Logger;

use constant narg => 2;

sub run {
    my ($self, $target, $uri, @options) = @_;
    my ($m, $mpath) = $target->is_mirrored;

    die loc("No such dump file: %1.\n", $self->{bootstrap})
        unless $self->{bootstrap} eq '-' ||
        $self->{bootstrap} =~ m{^(file|https?|ftp)://} ||
        $self->{bootstrap} eq 'auto' || -f ($self->{bootstrap});

    if (!$m) {
        $self->SUPER::run($target,$uri, @options);
        ($m, $mpath) = $target->is_mirrored;
    }
    # XXX: make sure the mirror is fresh and not synced at all

    die loc("%1 is not a mirrored path.\n", $target->depotpath) if !$m;
    die loc("%1 is inside a mirrored path.\n", $target->depotpath) if $mpath;

    if ( $self->{bootstrap} eq 'auto' ) {
        my $ra = $m->_backend->_new_ra;
        $ra->reparent( $ra->get_repos_root() );
        my %prop = %{ ( $ra->get_file( '', $ra->get_latest_revnum, undef ) )[1] };
        $m->_backend->_ra_finished($ra);
        $self->{bootstrap} = $prop{'svk:dump-url'};
    }

    $logger->info( loc("Bootstrapping mirror from dump") );
    $m->bootstrap($self->{bootstrap}); # load from dumpfile
    print loc("Mirror path '%1' synced from dumpfile.\n", $target->depotpath);
    return;
}

package SVK::Command::Mirror::upgrade;
use base qw(SVK::Command::Mirror);
use SVK::I18N;
use SVK::Logger;

use constant narg => 1;

sub run {
    my ($self, $target) = @_;
    $logger->info( loc("nothing to upgrade"));
    return;
}

package SVK::Command::Mirror::unlock;
use base qw(SVK::Command::Mirror);
use SVK::I18N;
use SVK::Logger;

use constant narg => 1;

sub run {
    my ($self, $target) = @_;
    $target->depot->mirror->unlock($target->path_anchor);
    $logger->info( loc ("mirror locks on %1 removed.\n", $target->report));
    return;
}

package SVK::Command::Mirror::list;
use base qw(SVK::Command::Mirror);
use SVK::I18N;
use SVK::Logger;
use List::Util qw( max );

sub parse_arg {
    my ($self, @arg) = @_;
    return (@arg ? @arg : undef);
}

sub run {
    my ( $self, $target ) = @_;

    my @mirror_columns;
    my @depots
        = defined $target
        ? @_[ 1 .. $#_ ]
        : sort keys %{ $self->{xd}{depotmap} }
        ;
    DEPOT:
    foreach my $depot (@depots) {
        $depot =~ s{/}{}g;
        $target = eval { $self->arg_depotpath("/$depot/") };
        if ($@) {
            warn loc( "Depot /%1/ not loadable.\n", $depot );
            next DEPOT;
        }
        my $depot_name = $target->depotname;
        foreach my $path ( $target->depot->mirror->entries ) {
            my $m = $target->depot->mirror->get($path);
            push @mirror_columns, [ "/$depot_name$path", $m->url ];
        }
    }

    return unless @mirror_columns;

    my $max_depot_path = max map { length $_->[0] } @mirror_columns;
    my $max_uri        = max map { length $_->[1] } @mirror_columns;

    my $fmt = "%-${max_depot_path}s   %-s\n";
    $logger->info(sprintf $fmt, loc('Path'), loc('Source'));
    $logger->info( '=' x ( $max_depot_path + $max_uri + 3 ));

    $logger->info(sprintf $fmt, @$_ )for @mirror_columns;

    return;
}

package SVK::Command::Mirror::recover;
use base qw(SVK::Command::Mirror);
use SVK::Util qw( traverse_history get_prompt );
use SVK::I18N;
use SVK::Logger;

use constant narg => 1;

sub run {
    my ($self, $target, $source, @options) = @_;
    die loc("recover not supported.\n");
    my ($m, $mpath) = $target->is_mirrored;

    $self->recover_headrev ($target, $m);
    $self->recover_list_entry ($target, $m);
    return;
}

sub recover_headrev {
    my ($self, $target, $m) = @_;

    my $fs = $target->repos->fs;
    my ($props, $headrev, $rev, $firstrev, $skipped, $uuid, $rrev);

    traverse_history (
        root        => $fs->revision_root ($fs->youngest_rev),
        path        => $m->{target_path},
        cross       => 1,
        callback    => sub {
            $rev = $_[1];
            $firstrev ||= $rev;
            $logger->info(loc("Analyzing revision %1...\n", $rev),
                  ('-' x 70),"\n",
                  $fs->revision_prop ($rev, 'svn:log'));

            if ( $headrev = $fs->revision_prop ($rev, 'svm:headrev') ) {
                ($uuid, $rrev) = split(/[:\n]/, $headrev);
                $props = $fs->revision_proplist($rev);
                get_prompt(loc(
                    "Found merge ticket at revision %1 (remote %2); use it? (y/n) ",
                    $rev, $rrev
                ), qr/^[YyNn]/) =~ /^[Nn]/ or return 0; # last
                undef $headrev;
            }
            $skipped++;
            return 1;
        },
    );

    if (!$headrev) {
        die loc("No mirror history found; cannot recover.\n");
    }

    if (!$skipped) {
        $logger->warn(loc("No need to revert; it is already the head revision."));
        return;
    }

    get_prompt(
        loc("Revert to revision %1 and discard %*(%2,revision)? (y/n) ", $rev, $skipped),
        qr/^[YyNn]/,
    ) =~ /^[Yy]/ or die loc("Aborted.\n");

    $self->command(
        delete => { direct => 1, message => '' }
    )->run($target);

    $target->refresh_revision;
    $self->command(
        copy => { direct  => 1, message => '' },
    )->run($target->new(revision => $rev) => $target->new);

    # XXX - race condition? should get the last committed rev instead
    $target->refresh_revision;

    $self->command(
        propset => { direct  => 1, revprop => 1 },
    )->run($_ => $props->{$_}, $target) for sort grep {m/^sv[nm]/} keys %$props;

    $logger->info( loc("Mirror state successfully recovered."));
    return;
}

sub recover_list_entry {
    my ($self, $target, $m) = @_;

    my %mirrors = map { ($_ => 1) } SVN::Mirror::list_mirror ($target->repos);

    return if $mirrors{$m->{target_path}}++;

    $self->command ( propset => { direct => 1, message => 'foo' } )->run (
        'svm:mirror' => join ("\n", (grep length, sort keys %mirrors), ''),
        $self->arg_depotpath ('/'.$target->depotname.'/'),
    );

    $logger->info( loc("%1 added back to the list of mirrored paths.\n", $target->report));
    return;
}

1;

__DATA__

=head1 NAME

SVK::Command::Mirror - Initialize a mirrored depotpath

=head1 SYNOPSIS

 mirror [http|svn]://host/path DEPOTPATH

 # You may also list the target part first:
 mirror DEPOTPATH [http|svn]://host/path

 mirror --bootstrap=DUMPFILE DEPOTPATH [http|svn]://host/path 
 mirror --list [DEPOTNAME...]
 mirror --relocate DEPOTPATH [http|svn]://host/path 
 mirror --detach DEPOTPATH
 mirror --recover DEPOTPATH

 mirror --upgrade //
 mirror --upgrade /DEPOTNAME/

=head1 OPTIONS

 -b [--bootstrap]       : mirror from a dump file
 -l [--list]            : list mirrored paths
 -d [--detach]          : mark a depotpath as no longer mirrored
 --relocate             : change the upstream URI for the mirrored depotpath
 --recover              : recover the state of a mirror path
 --unlock               : forcibly remove stalled locks on a mirror
 --upgrade              : upgrade mirror state to the latest version

