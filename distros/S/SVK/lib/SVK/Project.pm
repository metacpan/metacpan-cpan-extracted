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
package SVK::Project;
use strict;
use SVK::Version;  our $VERSION = $SVK::VERSION;
use Path::Class;
use SVK::Logger;
use SVK::I18N;
use base 'Class::Accessor::Fast';
use autouse 'SVK::Util' => qw( reformat_svn_date );

__PACKAGE__->mk_accessors(
    qw(name trunk branch_location tag_location local_root depot));

=head1 NAME

SVK::Project - SVK project class

=head1 SYNOPSIS

 See below

=head1 DESCRIPTION

The class represents a project within svk.

=cut

use List::MoreUtils 'apply';

sub branches {
    my ( $self, $local ) = @_;

    my $fs              = $self->depot->repos->fs;
    my $root            = $fs->revision_root( $fs->youngest_rev );
    my $branch_location = $local ? $self->local_root : $self->branch_location;

    return [ apply {$_->[0] =~ s{^\Q$branch_location\E/}{}}
        @{ $self->_find_branches( $root, $branch_location ) } ];
}

sub tags {
    my ( $self ) = @_;
    return [] unless $self->tag_location;

    my $fs              = $self->depot->repos->fs;
    my $root            = $fs->revision_root( $fs->youngest_rev );
    my $tag_location    = $self->tag_location;

    return [ apply {$_->[0] =~ s{^\Q$tag_location\E/}{}}
        @{ $self->_find_branches( $root, $tag_location ) } ];
}

sub _find_branches {
    my ( $self, $root, $path ) = @_;
    my $pool    = SVN::Pool->new_default;
    return [] if $SVN::Node::none == $root->check_path($path);
    my $entries = $root->dir_entries($path);

    my $trunk = SVK::Path->real_new(
        {   depot    => $self->depot,
            revision => $root->revision_root_revision,
            path     => $self->trunk
        }
    );

    my @branches;

    for my $entry ( sort keys %$entries ) {
        next unless $entries->{$entry}->kind == $SVN::Node::dir;
        my $b = $trunk->mclone( path => $path . '/' . $entry );
        next if $b->path eq $trunk->path;

        push @branches, $b->related_to($trunk)
            ? [$b->path, $self->{verbose} ? ":\n    ".$self->lastchanged_info($b) : ""]
            : @{ $self->_find_branches( $root, $path . '/' . $entry ) };
    }
    return \@branches;
}

sub lastchanged_info {
    my ($self, $target) = @_;
    if (defined( my $lastchanged = $target->root->node_created_rev( $target->path ))) {
	my $date
	    = $target->root->fs->revision_prop( $lastchanged, 'svn:date' );
	my $author
	    = $target->root->fs->revision_prop( $lastchanged, 'svn:author' );
	return sprintf (
	    "Last Changed Rev: %s (%s, by %s)",
	    $lastchanged,
	    reformat_svn_date( "%Y-%m-%d", $date ),
	    $author
	);
    }
}

sub allprojects {
    my ($self, $pathobj) = @_;

    my $fs              = $pathobj->depot->repos->fs;
    my $root            = $fs->revision_root( $fs->youngest_rev );
    my @all_mirrors     = split "\n", $root->node_prop('/','svm:mirror') || '';
    my $prop_path = '';
    my @projects;

    foreach my $m_path (@all_mirrors) {
	if ($pathobj->path eq '/') {
	    my $proj = $self->_create_from_prop($pathobj, $root, $m_path);
	    push @projects, $proj if $proj;
	}
    }
    return \@projects;
}

sub create_from_prop {
    my ($self, $pathobj, $pname) = @_;

    my $fs              = $pathobj->depot->repos->fs;
    my $root            = $fs->revision_root( $fs->youngest_rev );
    my @all_mirrors     = split "\n", $root->node_prop('/','svm:mirror') || '';
    my $prop_path = '';
    my $proj;

    foreach my $m_path (@all_mirrors) {
	if ($pathobj->path eq '/' and $pname) { # in non-wc path
	    $proj = $self->_create_from_prop($pathobj, $root, $m_path, $pname);
	    return $proj if $proj;
	} elsif ($pathobj->_to_pclass("/local")->subsumes($pathobj->path)) {
	    $proj = $self->_create_from_prop($pathobj, $root, $m_path, $pname);
	    return $proj if $proj;
	} else {
	    if ($pathobj->path =~ m/^$m_path/) {
		$prop_path = $m_path;
		last;
	    }
	}
    }
    $proj = $self->_create_from_prop($pathobj, $root, $prop_path, $pname);
    return $proj if $proj;
    return $self->_create_from_prop($pathobj, $root, $prop_path, $pname, 1);
}

sub _project_names {
    my ($self, $allprops, $pname) = @_;
    my ($depotroot)     = '/';
    return
        map  { $_ => 1}
	grep { (1 and !$pname) or ($_ eq $pname)  } # if specified pname, the grep it only
	grep { $_ =~ s/^svk:project:([^:]+):.*$/$1/ }
	grep { $allprops->{$_} =~ /$depotroot/ } sort keys %{$allprops};
}

sub _project_paths {
    my ($self, $allprops) = @_;
    return
        map  { $allprops->{$_} => $_ }
	grep { $_ =~ m/^svk:project/ } sort keys %{$allprops};
}

sub _create_from_prop {
    my ($self, $pathobj, $root, $prop_path, $pname, $from_local) = @_;
    my $allprops        = $root->node_proplist($from_local ? '/' : $prop_path);
    my %projnames = $self->_project_names($allprops, $pname);
    return unless %projnames;
    
    # Given a lists of projects: 'rt32', 'rt34', 'rt38' in lexcialorder
    # if the suffix of prop_path matches $project_name like /mirror/rt38 matches rt38
    # then 'rt38' should be used to try before 'rt36', 'rt32'... 

    for my $project_name ( sort { $prop_path =~ m/$b$/ } keys %projnames)  {
	$prop_path = $allprops->{'svk:project:'.$project_name.':root'}
	    if ($allprops->{'svk:project:'.$project_name.':root'} and
		($from_local || $prop_path eq '/'));
	my %props = 
#	    map { $_ => '/'.$allprops->{'svk:project:'.$project_name.':'.$_} }
	    map {
		my $prop = $allprops->{'svk:project:'.$project_name.':'.$_};
		$prop =~ s{/$}{} if $prop;
		$prop =~ s{^/}{} if $prop;
		$_ => $prop ? $prop_path.'/'.$prop : '' }
		('path-trunk', 'path-branches', 'path-tags');
    
	# only the current path matches one of the branches/trunk/tags, the project
	# is returned
	for my $key (keys %props) {
	    next unless $props{$key};
	    return SVK::Project->new(
		{   
		    name            => $project_name,
		    depot           => $pathobj->depot,
		    trunk           => $props{'path-trunk'},
		    branch_location => $props{'path-branches'},
		    tag_location    => $props{'path-tags'},
		    local_root      => "/local/${project_name}",
		}) if $pathobj->path =~ m/^$props{$key}/ or $props{$key} =~ m/^$pathobj->{'path'}/
		      or $pathobj->path =~ m{^/local/$project_name};
	}
    }
    return undef;
}

sub create_from_path {
    my ($self, $depot, $path, $pname) = @_;
    my $rev = undef;

    my $path_obj = SVK::Path->real_new(
        {   depot    => $depot,
            path     => $path
        }
    );
    $path_obj->refresh_revision;

    my ($project_name, $trunk_path, $branch_path, $tag_path) = 
	$self->_find_project_path($path_obj);

    return undef unless $project_name;
    return undef if $pname and $pname ne $project_name;
    return SVK::Project->new(
	{   
	    name            => $project_name,
	    depot           => $path_obj->depot,
	    trunk           => $trunk_path,
	    branch_location => $branch_path,
	    tag_location    => $tag_path,
	    local_root      => "/local/${project_name}",
	});
}

sub _check_project_path {
    my ($self, $path_obj, $trunk_path, $branch_path, $tag_path) = @_;

    my $checked_result = 1;
    # check trunk, branch, tag, these should be metadata-ed 
    # we check if the structure of mirror is correct, otherwise go again
    for my $_path ($trunk_path, $branch_path, $tag_path) {
        unless ($path_obj->root->check_path($_path) == $SVN::Node::dir) {
            if ($tag_path eq $_path) { # tags directory is optional
                $checked_result = 2; # no tags
            }
            else {
                return 0;
            }
        }
    }
    return $checked_result;
}

# this is heuristics guessing of project and should be replaced
# eventually when we can define project meta data.
sub _find_project_path {
    my ($self, $path_obj) = @_;

    my ($mirror_path,$project_name);
    my ($trunk_path, $branch_path, $tag_path);
    my $current_path = $path_obj->_to_pclass($path_obj->path);

    if ($path_obj->_to_pclass("/local")->subsumes($current_path)) { # guess if in local branch
	# should only be 1 entry
	$current_path = ($path_obj->copy_ancestors)[0]->[0] if $path_obj->copy_ancestors;
	$path_obj = $path_obj->copied_from if $path_obj->copied_from;
    }

    # Finding inverse layout first
    my ($path) = $current_path =~ m{^/(.+?/(?:trunk|branches|tags)/[^/]+)};
    if ($path) {
        ($mirror_path, $project_name) = # always assume the last entry the projectname
            $path =~ m{^(.*/)?(?:trunk|branches|tags)/(.+)$}; 
        if ($project_name and $path_obj->root->check_path($mirror_path) == $SVN::Node::dir) {
            ($trunk_path, $branch_path, $tag_path) = 
                map { $mirror_path.$_.'/'.$project_name } ('trunk', 'branches', 'tags');
            my $result = $self->_check_project_path ($path_obj, $trunk_path, $branch_path, $tag_path);
	    $tag_path = '' if $result == 2;
            return ($project_name, $trunk_path, $branch_path, $tag_path) if $result > 0;
        }
        $project_name = '';
        $path = '';
    }
    # not found in inverse layout, else 
    ($path) = $current_path =~ m{^(.*?)(?:/(?:trunk|branches/.*?|tags/.*?))?/?$};

    while (!$project_name) {
	($mirror_path,$project_name) = # always assume the last entry the projectname
	    $path =~ m{^(.*/)?([\w\-_]+)$}; 
	return undef unless $project_name; # can' find any project_name
	$mirror_path ||= '';

	($trunk_path, $branch_path, $tag_path) = 
	    map { $mirror_path.$project_name."/".$_ } ('trunk', 'branches', 'tags');
        return undef unless ($path_obj->root->check_path($mirror_path.$project_name) == $SVN::Node::dir);
	my $result = $self->_check_project_path ($path_obj, $trunk_path, $branch_path, $tag_path);
	# if not the last entry, then the mirror_path should contains
	# trunk/branches/tags, otherwise no need to test
	($path) = $mirror_path =~ m{^(.+(?=/(?:trunk|branches|tags)))}
	    unless $result != 0;
	$tag_path = '' if $result == 2;
	$project_name = '' unless $result;
	return undef unless $path;
    }
    return ($project_name, $trunk_path, $branch_path, $tag_path);
}

sub depotpath_in_branch_or_tag {
    my ($self, $name) = @_;
    # return 1 for branch, 2 for tag, others => 0
    return '/'.dir($self->depot->depotname,$self->branch_location,$name)->as_foreign('Unix')
	if grep { $_->[0] eq $name } @{$self->branches};
    return '/'.dir($self->depot->depotname,$self->tag_location,$name)->as_foreign('Unix')
	if grep { $_ eq $name } @{$self->tags};
    return ;
}

sub branch_name {
    my ($self, $bpath, $is_local) = @_;
    return 'trunk' if (dir($self->trunk)->subsumes($bpath));
    my $branch_location = $is_local ? $self->local_root : $self->branch_location;
    $bpath =~ s{^\Q$branch_location\E/}{};
    my $pbname;
    ($pbname) = grep { my $base = $_->[0]; $bpath =~ m#^$base(/|$)# } @{$self->branches};
    return $pbname->[0] if $pbname;
    return $bpath;
}

sub branch_path {
    my ($self, $bname, $is_local) = @_;
    my $branch_path = 
        ($is_local ?
            $self->local_root."/$bname"
            :
            ($bname ne 'trunk' ?
                $self->branch_location . "/$bname" : $self->trunk)
        );
    $branch_path =
	'/'.dir($self->depot->depotname)->subdir($branch_path)->as_foreign('Unix');
    return $branch_path;
}

sub tag_name {
    my ($self, $bpath) = @_;
    return 'trunk' if (dir($self->trunk)->subsumes($bpath));
    my $tag_location = $self->tag_location;
    $bpath =~ s{^\Q$tag_location\E/}{};
    my $pbname;
    ($pbname) = grep { $bpath =~ m#^$_(/|$)# } @{$self->tags};
    return $pbname if $pbname;
    return $bpath;
}

sub tag_path {
    my ($self, $tname) = @_;
    my $tag_path = ($tname ne 'trunk' ?  $self->tag_location . "/$tname" : $self->trunk);
    $tag_path =
	'/'.dir($self->depot->depotname)->subdir($tag_path)->as_foreign('Unix');
    return $tag_path;
}

sub info {
    my ($self, $target, $verbose) = @_;

    $logger->info ( loc("Project name: %1\n", $self->name));
    if ($target->isa('SVK::Path::Checkout')) {
	my $where = "online";
	my $bname = '';
	if (dir($self->trunk)->subsumes($target->path)) {
	    $bname = 'trunk';
	} elsif (dir($self->branch_location)->subsumes($target->path)) {
	    $bname = $self->branch_name($target->path);
	} elsif ($self->tag_location and dir($self->tag_location)->subsumes($target->path)) {
	    $bname = $self->tag_name($target->path);
	} elsif ($target->_to_pclass("/local")->subsumes($target->path)) {
	    $where = 'offline';
	    $bname = $self->branch_name($target->path,1);
	}

	if ($where) {
	    $logger->info ( loc("Branch: %1 (%2)\n", $bname, $where ));
	    return unless $verbose;
	    $logger->info ( loc("Revision: %1\n", $target->revision));
	    $logger->info ( loc("Repository path: %1\n", $target->depotpath ));
	    if ($where ne 'trunk') { # project trunk should not have Copied info
		for ($target->copy_ancestors) {
		    next if $bname eq $self->branch_name($_->[0]);
		    $logger->info( loc("Copied From: %1@%2\n", $self->branch_name($_->[0]), $_->[1]));
		    last;
		}
		$self->{xd} = $target->{xd};
		$self->{merge} = SVK::Merge->new (%$self);
		my $minfo = $self->{merge}->find_merge_sources ($target, 0,1);
		for (sort { $minfo->{$b} <=> $minfo->{$a} } keys %$minfo) {
		    $logger->info( loc("Merged From: %1@%2\n",$self->branch_name((split/:/)[1]),$minfo->{$_}));
		    last;
		}
	    }
	}
    }
}

sub in_which_project {
    my ($self, $pathobj) = @_;

    my $fs              = $pathobj->depot->repos->fs;
    my $root            = $fs->revision_root( $fs->youngest_rev );
    my @all_mirrors     = split "\n", $root->node_prop('/','svm:mirror') || '';
    my $prop_path       = '/';
    foreach my $m_path (@all_mirrors) {
        if ($pathobj->path =~ m/^$m_path/) {
            $prop_path = $m_path;
            last;
        }
    }
    my $from_local      = $pathobj->_to_pclass("/local")->subsumes($pathobj->path);
    my $allprops        = $root->node_proplist($from_local ? '/' : $prop_path);
    my %projpaths       = $self->_project_paths($allprops);
    for my $path (sort { $b ne $a } keys %projpaths) { # reverse sort to ensure subsume
        next unless length($path);
	if ($pathobj->_to_pclass($prop_path.$path)->subsumes($pathobj->path) or
	    $pathobj->_to_pclass($pathobj->path)->subsumes($prop_path.$path)) {
	    my ($pname) = $projpaths{$path} =~ m/^svk:project:(.*?):path/;
	    return $pname;
	}
    }
    return;
}
1;
