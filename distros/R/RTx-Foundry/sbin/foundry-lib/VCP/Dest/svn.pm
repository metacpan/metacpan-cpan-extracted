package VCP::Dest::svn;

=head1 NAME

VCP::Dest::svn - subversion destination driver

=head1 SYNOPSIS

   vcp <source> svn:file:///path/to/repo:

=head1 DESCRIPTION

The subversion destination driver for vcp.

The current implementation is using the C<svn> command line interface
to do a series of commits and other operations. It also works with
remote repository.

=head1 OPTIONS

=over

=item --init-svnrepo

Initialize the destination subversion repository.

If you don't want to use the --init-svnrepo but the repository created
by yourself, make sure that pre-revprop-change hook is a script
existing 0.

=item --delete-svnrepo

Remove the subversion repository in the destination if exists.

=item --encoding

Specify the --encoding argument passed to C<svn commit>. Note that
this should be obsolated by a comment encoding converter filter
instead in the future.

=back

=head1 BRANCHES AND TAGS

You need to specify the Map filter for vcp to work properly with
branches. see EXMAPLES below.

Since in subversion branches and tags are just C<svn cp>, you only
need to enable <VCP::Filter::svnlabeller> to produce placeholder
revisions for labels. L<VCP::Dest::svn> will take care of the rest.

=head1 PERFORMANCE

=over

=item interfacing with subversion

A svndumpfile generating destination driver will supposedly boost the
performance. But this will require keeping file system information in
our code.

A perl binding version (if perl binding is available of course) might
also be good.

=item svn commit performance

subversion (as for 0.25) locks the tree of the parent directory of the
committing target for some unknown reasons. this makes it very slow to
commit when your subversion is with lots of branches and tags. And we
have to work with the whole subveresion tree instead of just a working
copy and C<svn switch> back and forth, due to the fact that CVS
branches and tags could be tagged from mixed branches. We have to do
one or more single file C<svn cp> after the optimal top-level C<svn
cp> to fix the resulting tag or branch. You don't really want to see a
branch with a lot single file C<svn cp> commits, so we have to do wc
file copy and then commit them all at a time.

A patch for checking out the neccessary tags and branches is also
available, but this requires the patch posted to subversion issue
tracker 695 to be applied to svn.

=item too many placeholders

For repositories with lots of tags, L<VCP::Filter::svnlabeller>
generates a large number of placeholder revisions. This would cause
consuming too much memory. A workaround is in progress.

=head1 NOTES FOR CONVERTING FROM CVS

=over

=item

If the source cvs repository is remote or you are using
--use-cvs, you should set the timezone environment variable to GMT.
otherwise the fast checkout of <VCP::Source::cvs> would fail. although
it will fallback to individual checkout.

=item

You should enable <VCP::Filter::cvslabelonbranch>. If a tag is
laid on the unmodified first revision after a branching or tagging,
the file will have the tag pointing to the original branch. The filter
will consolidate the best and allowed source branch base on
observation of where the branch on other files come from.

=item

you could use the test script C<t/99cvs2svn.t> to do the
conversion. the script will also check if branches and tags checkout
from original cvs and converted subversion are identical. you could
invoke the script with:

make test TEST_FILES=t/99cvs2svn.t TEST_VERBOSE=1 VCP_CVSROOT=/path/to/cvsrepo VCP_KEEP_TESTROOT=1

The script also sets TZ=GMT as suggested above.

=back

=head1 EXAMPLE

a typical .vcp file converting cvs to subversion:

Source: cvs:/tmp/cvstest/cvsroot:module --use-cvs --continue

Destination: svn:file:///tmp/svntest: --init-svnrepo --delete-svnrepo

Map:
        module/(...)<>            trunk/$1
        module/(...)<(*)>         branches/$2/$1

CVSLabelonBranch:

SVNLabeller:

ChangeSets:
       time                     <=60
       user_id                  equal
       comment                  equal
       branched_rev_branch_id   equal

=cut

$VERSION = 1 ;

use strict ;
use vars qw( $debug ) ;

$debug = 0 ;

use Carp ;
use File::Basename ;
use File::Path ;
use VCP::Debug ':debug' ;
use VCP::Rev ('iso8601format');
use VCP::Utils ('escape_filename');
use URI;
use URI::Escape;
use SVN::Core;
use SVN::Repos;
use SVN::Fs;
use SVN::Delta;
use base qw( VCP::Dest VCP::Utils::svn ) ;
use fields qw(SVN_PENDING SVN_PREV_CHANGE_ID SVN_URI SVN_ENCODING SVN_REPOS
	      SVN_FS SVN_EDITOR SVN_POOL SVN_PATHS SVN_REVROOT SVN_BASEREV
	      SVN_TXNROOT);

sub new {
   my $class = shift ;
   $class = ref $class || $class ;

   my $self = $class->SUPER::new( @_ ) ;

   ## Parse the options
   my ( $spec, $options ) = @_ ;

   $self->parse_repo_spec( $spec ) ;
   $self->{SVN_URI} = URI->new($self->repo_server);

   $self->repo_id( "svn:" . $self->repo_server );
   $self->deduce_rev_root( $self->repo_filespec ) ;

   $self->parse_options(
      $options,
      "init-svnrepo!"            => \my $init_svnrepo,
      "delete-svnrepo!"            => \my $delete_svnrepo,
      "encoding=s"		=> sub { $self->{SVN_ENCODING} = $_[1] },
   );

   $self->{SVN_ENCODING} = "UTF-8" unless defined $self->{SVN_ENCODING};

   if ($init_svnrepo) {
       die "can't create remote repository"
	   unless $self->uri->scheme eq 'file';

       if ($delete_svnrepo) {
	   rmtree([ $self->uri->path]) if -d $self->uri->path;

	   $self->rev_map->delete_db;
	   $self->head_revs->delete_db;
	   $self->files->delete_db;
       }

       debug "creating repo" if debugging;
       $self->{SVN_REPOS} = SVN::Repos::create($self->uri->path, undef, undef, undef, undef);
       $self->{SVN_FS} = $self->{SVN_REPOS}->fs;
       $self->{SVN_POOL} = SVN::Pool->new;

   }

   $self->rev_map->open_db;
   $self->head_revs->open_db;
   $self->files->open_db;

   return $self ;
}

sub uri {
    $_[0]{SVN_URI};
}

sub prunedir {
    my ($self, $work_path) = @_;
    my ($vol, $work_dir, undef) = File::Spec->splitpath( $work_path ) ;
    my @dirs = File::Spec->splitdir($work_dir);
    pop @dirs; # get rid of the last /
    my $top = $self->work_path;
    my @pruned;

    while ($work_dir =~ m!$top/(trunk|(tags|branches)/[^/]+)/.+! &&
	   $#{[<$work_dir.*>,<$work_dir*>]} == 2) { # we have .svn
	$work_dir =~ s!^$top/!!;
	push @pruned, $work_dir;
	pop @dirs;
	$work_dir = File::Spec->catdir(@dirs, '');
    }

    return @pruned;
}

sub svn_prunedir {
    my ($self, $path) = @_;
    my ($vol, $dir, undef) = File::Spec->splitpath( $path ) ;
    $dir =~ s|/$||;
    my @dirs = File::Spec->splitdir($dir);
    my @pruned;

    while ($#dirs > 0 && !%{SVN::Fs::dir_entries($self->{SVN_TXNROOT}, $dir,
						 $self->{SVN_POOL})}) {
	$self->{SVN_EDITOR}->close_directory ($self->{SVN_PATHS}{$dir},
					      $self->{SVN_POOL});
	delete $self->{SVN_PATHS}{$dir};
	push @pruned, $dir;
	pop @dirs;
	$dir = File::Spec->catdir(@dirs);
    }
    return @pruned;
}

sub mkpdir {
    my ($self, $work_path) = @_;
    my ($vol, $work_dir, undef) = File::Spec->splitpath( $work_path ) ;

    unless ( -d $work_dir ) {
	my @dirs = File::Spec->splitdir( $work_dir ) ;
	my $this_dir = shift @dirs  ;
	my $base_dir = File::Spec->catpath($vol, $this_dir, "" ) ;
	do {
	    if ( length $base_dir && ! -d $base_dir ) {
		$self->mkdir( $base_dir ) ;
		$self->svn( ["add", $base_dir] ) ;
	    }
	    $this_dir = shift @dirs  ;
	    $base_dir = File::Spec->catdir( $base_dir, $this_dir ) ;
	} while @dirs ;
    }
}

sub svn_mkpdir {
    my ($self, $path) = @_;
    use Carp;
    confess unless $path;
    my (undef, $dir, undef) = File::Spec->splitpath( $path ) ;
    $dir =~ s|/$||;
    my (undef, $parentdir, undef) = File::Spec->splitpath( $dir ) ;
    $parentdir =~ s|/$||;

    my $pbaton = $self->{SVN_PATHS}{$parentdir} ||=
	$self->svn_mkpdir ($dir);
    if (SVN::Fs::check_path($self->{SVN_TXNROOT}, $dir, $self->{SVN_POOL})
	== $SVN::Core::node_dir) {
	$self->{SVN_PATHS}{$dir} = $self->{SVN_EDITOR}->
	    open_directory ($dir, $pbaton, -1, $self->{SVN_POOL});
    }
    else {
	$self->{SVN_PATHS}{$dir} = $self->{SVN_EDITOR}->
	    add_directory ($dir, $pbaton, undef, 0, $self->{SVN_POOL});
    }
    return $self->{SVN_PATHS}{$dir};
}

sub svn_prunebaton {
    my ($self, $path) = @_;
    use YAML;
    die unless $path;
    my (undef, $dir, undef) = File::Spec->splitpath( $path ) ;
    $dir =~ s|/$||;

    if (exists $self->{SVN_PATHS}{$path}) {
	$self->{SVN_EDITOR}->close_directory ($self->{SVN_PATHS}{$path}, $self->{SVN_POOL});
	delete $self->{SVN_PATHS}{$path};
    }
    return $self->{SVN_PATHS}{$dir};
}

sub svn_rm {
    my $self = shift;
    my @to_rm = @_;
    my @rmdir;
    my $pool = $self->{SVN_POOL};
    for (@to_rm) {
	my $pb = $self->svn_mkpdir($_);
	$self->{SVN_EDITOR}->delete_entry($_, $self->{SVN_BASEREV},
					  $pb, $pool);
	if (my @pruned = $self->svn_prunedir($_)) {
	    @rmdir = grep { substr($_, 0, 1+length($pruned[-1]))
				ne $pruned[-1].'/'} @rmdir;
	    push @rmdir, $pruned[-1];
	}
    }

    for (@rmdir) {
	my $pool = $self->{SVN_POOL};
	my $pb = $self->svn_mkpdir($_);
	$self->{SVN_EDITOR}->delete_entry($_, $self->{SVN_BASEREV},
					  $pb, $pool);
    }
}

sub _repo_escape {
    local $_ = shift;
    s/%/%25/g;
    return $_;
}

sub _svn_commit_revid {
    return $1 if $_[0] =~ m/Committed revision (\d+)\./;
    return ();
}

sub branch_commit_message {
    my ($self, $branch, $revs) = @_;
    my @label = $revs->[0]->labels;

    ($#label == 0) ? "tagging $label[0]" : "creating branch $branch";
}

sub create_branch {
    my ($self, $branch, $revs) = @_;
    my $branchpoint = 0;
    my $hardlimit = -1;
    # placeholder with label is tagging
    my @label = $revs->[0]->labels;

    my $tagging = ($#label == 0);
    my $dest = ($tagging) ? 'tags/'.uri_escape($label[0]) :
	'branches/'.uri_escape($branch);
    my %filename;
    my @svnrev;

    if ($#{$revs} > 0 && $branch =~ m/^_branch_/) {
	return map { $self->create_branch ($branch, [$_]) } @$revs;
    }

    unless ($tagging) {
	my %frombranch;
	push @{$frombranch{$_->previous->branch_id || 'trunk'}}, $_
	    for @$revs;
	if (keys %frombranch > 1) {
	    debug "branch from different branches. split to multiple svn cp:".
		join(',',keys %frombranch) if debugging;
	    return map { $self->create_branch ($branch, $frombranch{$_}) }
	        sort {$#{$frombranch{$b}} <=> $#{$frombranch{$a}}} keys %frombranch;
	}
    }

    my $frombranch = 'trunk';
    my $frombranchstem = 'trunk';

    if ($revs->[0]->previous && $revs->[0]->previous->branch_id) {
	$frombranch = 'branches/'.uri_escape($revs->[0]->previous->branch_id);
	$frombranchstem = 'branches/'.$revs->[0]->previous->branch_id;
    }

    my @fromrev;
    my (@defer, @rev);
    debug "about to create branch $branch" if debugging;

    # better check on this derived branching point rev
    for my $r (@$revs) {
	my ($revid) = $self->rev_map->get([$r->source_repo_id, $r->previous_id])
	    if $self->rev_map->exists([$r->source_repo_id, $r->previous_id]);
	push @fromrev, $revid;

	my ($headrev) = $self->head_revs->get([$r->source_repo_id, $r->previous->source_filebranch_id]);

	next unless $headrev;

	my $hid = $r->previous_id;
	$hid =~ s/\#.*$/#$headrev/;
	if ($headrev ne $r->previous->rev_id &&
	    $self->rev_map->exists([$r->source_repo_id, $hid])) {
	    debug "head of ".$r->name." is already $headrev (branching from ".$r->previous_id if debugging;

	    my $bound = $r->previous_id;
	    $bound =~ s/(\d+)$//;
	    $bound .= $1+1; # hell! need rev->next

	    my ($limit) = $self->rev_map->get([$r->source_repo_id, $bound]);
	    $hardlimit = $limit if $hardlimit == -1 || $limit < $hardlimit;
	}
    }

    for my $r (@$revs) {
	my $from = shift @fromrev;
	if ($hardlimit != -1 && $from >= $hardlimit) {
	    push @defer, $r;
	}
	else {
	    my $expect = $r->name;
	    $tagging ? $expect =~ s!^$frombranchstem/!$dest/!
		    : $expect =~ s|^branches/$branch/|$dest/|;
	    $filename{$expect} = $r;
	    debug "awaiting $expect ($from < $hardlimit) on new branch"
		if debugging;

	    $branchpoint = $from
		if defined $from && $from > $branchpoint;
	}
    }

    return () unless $branchpoint;

    $self->svn_mkpdir ("$dest/")
	if $branch =~ m/^_branch_/ &&
	    SVN::Fs::check_path($self->{SVN_TXNROOT}, $dest, $self->{SVN_POOL})
		    != $SVN::Core::node_dir;
    my $output;
    # likely to be added on trunk and manually tag -b again
    if (SVN::Fs::check_path($self->{SVN_TXNROOT}, $dest, $self->{SVN_POOL})
	== $SVN::Core::node_dir) {
#    if (-d $self->work_path($dest) ) {
    	    for my $r (@$revs) {
		next if $r->previous && $r->previous->action eq 'delete';

		my $stem = $r->name;
		$tagging ? $stem =~ s!^$frombranchstem/!! 
		    : $stem =~ s|^branches/$branch/||;

		my $dbaton = $self->svn_mkpdir("$dest/$stem");

		my $fbaton = $self->{SVN_EDITOR}->
		    add_file ("$dest/$stem", $dbaton,
			      $self->uri."/$frombranch/$stem", $branchpoint,
			      $self->{SVN_POOL});

=comment

		$self->svn(['cp', -e "$frombranch/$stem" ?
			    "$frombranch/$stem" :
			    _repo_escape ($self->uri."/$frombranch/$stem"),
			    '-r', $branchpoint, "$dest/$stem"]);

=cut

	    }
	    return ();
	    $self->svn(['commit', '-m', "copy from $frombranch to $dest", $dest], undef, \$output);
	    return _svn_commit_revid ($output);
	}

    my $dbaton = $self->svn_mkpdir ($dest);

    debug "create branch from $frombranch\@$branchpoint to $dest"
	if debugging;
    $self->{SVN_EDITOR}->add_directory ($dest, $dbaton,
					$self->uri."/$frombranch",
					$branchpoint,
					$self->{SVN_POOL});

    my $editor = CleanupEditor->new;
    $editor->{expect} = \%filename;
    $editor->{to_rm} = [];
    SVN::Repos::dir_delta ($self->{SVN_REVROOT},
			   '',
			   undef, #srcentry
			   $self->{SVN_TXNROOT},
			   '',
			   $editor,
			   0,1,0,0,
			   $self->{SVN_POOL}
			  );

    $self->svn_rm (@{$editor->{to_rm}});
    $self->create_branch($branch, \@defer) if @defer;
    return ();

=comment

	$self->svn(['cp', _repo_escape ($self->uri.'/'.$frombranch),
		    '-r', $branchpoint,
		    _repo_escape ($self->uri."/$dest"), '-m', 
		    ($dest =~ '^branches' ? "creating branch $branch" :
		     "tagging $label[0]")], undef, \$output);

=cut

	my $afiles;
	$self->svn(['up', ($tagging ? 'tags' : 'branches')], undef, \$afiles);
	my @to_rm;
	for ($afiles =~ m/^A\s+(.*)$/mg) {
	    next if -d $self->work_path($_);
	    unless (exists $filename{$_}) {
		push @to_rm, $_ ;
		unlink $self->work_path($_);
		if (my @pruned = $self->prunedir($self->work_path($_))) {
		    @to_rm = grep { substr($_, 0, length($pruned[-1])) ne $pruned[-1] } @to_rm;
		    push @to_rm, $pruned[-1];
		}
	    }
	}

	debug "deferring incomplete branching" if debugging && @defer ;

	my @revs = (_svn_commit_revid ($output));
	if (@to_rm) {
	    $self->svn(['rm', @to_rm]);
	    $self->svn(['commit', '-m', "cleanup for files not belong to $dest", $dest], undef, \$output);
	    push @revs, _svn_commit_revid ($output);
	}

	return (@revs, @defer ? $self->create_branch($branch, \@defer) : ());

}

sub committed {
    my ($self, $revs, $rev, $date, $author) = @_;
    debug "committed $rev: ".$revs->[0]->as_string;
    $self->rev_map->set([$_->source_repo_id, $_->id], $rev)
	for @$revs;
    my $time = iso8601format($revs->[0]->time);
    $time =~ s/\s/T/;
    $time =~ s/Z/\.00000Z/;
    $self->{SVN_FS}->change_rev_prop($rev, 'svn:date', $time, $self->{SVN_POOL});
}

sub commit {
    my VCP::Dest::svn $self = shift ;
    my $output;
    my $revs = $self->{SVN_PENDING};
    my @svnrev;
    my $comment = $revs->[0]->comment;

    if ($revs->[0]->action eq "placeholder" ) {
	$revs = [map { ref($_) eq 'HASH' ? bless $_,'VCP::CheapRev' : $_ }
		 map { my $compact = $_->svn_info;
		       $_->set_svn_info([]);
		       $compact ? @$compact : $_ } @$revs];
	$comment = $self->branch_commit_message ($revs->[0]->branch_id, $revs);
    }

#    SVN::_Core::apr_pool_destroy($self->{SVN_POOL});
    $self->{SVN_POOL} ||= SVN::Pool->new;
    $self->{SVN_POOL}->clear;

    $self->{SVN_BASEREV} = $self->{SVN_FS}->youngest_rev;
    $self->{SVN_REVROOT} = $self->{SVN_FS}->revision_root
	($self->{SVN_BASEREV}, $self->{SVN_POOL});

    $self->{SVN_EDITOR} = new SVN::Delta::Editor
	SVN::Repos::get_commit_editor($self->{SVN_REPOS}, $self->uri.'/',
				      '/', $revs->[0]->user_id,
				      $comment,
				      sub {$self->committed($revs, @_)});
    $self->{SVN_PATHS}{''} = $self->{SVN_EDITOR}->open_root(0, $self->{SVN_POOL});
    my $repopath = $self->{SVN_URI}->path;
    my $txns = $self->{SVN_FS}->list_transactions($self->{SVN_POOL});
    die unless $#{$txns} == 0;

    $self->{SVN_TXNROOT} = $self->{SVN_FS}->open_txn($txns->[0], $self->{SVN_POOL})->root($self->{SVN_POOL});

    if ($revs->[0]->action eq 'placeholder') {
	push @svnrev, $self->create_branch($revs->[0]->branch_id, $revs);
    }
    else {
	my $comment = $revs->[0]->comment || '' ;

	my @source_fns = 
	    VCP::Revs->fetch_files(grep {$_->action ne 'delete'} @$revs);

	my @to_add;
	my @to_rm;

	for my $r (@$revs) {
	    my $work_path = $self->work_path( $r->name ) ;
	    my $dirbaton = $self->svn_mkpdir($r->name);

	    if ($r->action eq 'delete') {
		push @to_rm, $r->name;
	    }
	    else {
		my ( $source_fn ) = shift @source_fns;
		my $pool = $self->{SVN_POOL};
		my $fbaton;

		if (SVN::Fs::check_path ($self->{SVN_REVROOT}, $r->name, $self->{SVN_POOL}) == $SVN::Core::node_file) {
		    $fbaton = $self->{SVN_EDITOR}->open_file ($r->name, $dirbaton, $self->{SVN_BASEREV}, $pool);
		}
		else {
		    $fbaton = $self->{SVN_EDITOR}->add_file ($r->name, $dirbaton,
						 undef, -1, $pool);
		}


		my $fh;
		# implement SVN::Stream to wrap glob
		open $fh, $source_fn;
		my $ret = $self->{SVN_EDITOR}->apply_textdelta ($fbaton, undef, $pool);
		{
		local $/;
		SVN::_Delta::svn_txdelta_send_string(<$fh> || '',
						     @$ret, $pool);
	    }
		close $fh;
		$self->{SVN_EDITOR}->close_file ($fbaton, undef, $pool);

=comment

		if (-e $work_path) {
		    unlink $work_path or die "$! unlinking $work_path";
		}
		else {
		    push @to_add, $r->name;
		}

		link $source_fn, $work_path
		    or die "$! linking '$source_fn' -> '$work_path'" ;

		my $now = time;
		utime $now, $now, $work_path
		    or die "$! changing times on $work_path" 

=cut

	    }
	}



	if (@to_rm) {
	    $self->svn_rm (@to_rm);
	}

=comment

	if (@to_rm) {
	    $self->svn(['up', ($revs->[0]->branch_id ?
			       "branches/".$revs->[0]->branch_id : 
			       'trunk')]);

	    for (@to_rm) {
		my $work_path = $self->work_path($_);
	        unlink $work_path;
		if (my @pruned = $self->prunedir($work_path)) {
		    @to_rm = grep { substr($_, 0, length($pruned[-1])) ne $pruned[-1] } @to_rm;
		    push @to_rm, $pruned[-1];
		}
	    }
	    $self->svn(['rm', @to_rm]);
	}

	$self->svn(['add', @to_add]) if @to_add;

	$self->svn(['commit', '--encoding', $self->{SVN_ENCODING}, '-m', $comment, 
		    ($revs->[0]->branch_id ?
		     "branches/".$revs->[0]->branch_id : 
		     'trunk')], undef, \$output);
	push @svnrev, _svn_commit_revid($output);

=cut

	$self->head_revs->set([$_->source_repo_id, $_->source_filebranch_id],
			      $_->source_rev_id) for @$revs;

    }


    $self->{SVN_EDITOR}->close_edit($self->{SVN_POOL});
    undef $self->{SVN_PATHS};
return;
    if (@svnrev) {
	my $time = iso8601format($revs->[0]->time);
	$time =~ s/\s/T/;
	$time =~ s/Z/\.00000Z/;
	my $latest = 0;
	for (@svnrev) {
	    $self->svn(['propset', 'svn:date', '--revprop', '-r', $_, $time]);
	    $self->svn(['propset', 'svn:author', '--revprop', '-r', $_, $revs->[0]->user_id]);
	    $latest = $_ if $latest < $_;
	}
	$self->rev_map->set([$_->source_repo_id, $_->id], $latest)
	    for @$revs;
    }
    else {
	# we can't do force commit from svn commandline
	# so just set revmap to its previous
	for (@$revs) {
	    $self->rev_map->set([$_->source_repo_id, $_->id],
				$self->rev_map->get([$_->source_repo_id, $_->previous_id]))
		if $_->previous_id && $self->rev_map->exists([$_->source_repo_id, $_->previous_id]);
	}
    }
}

sub checkout_file {
    my VCP::Dest::svn $self = shift;
    my ( $r ) = @_ ;

    # supposedly it only makes sense for comparing the head with the
    # base_rev, otherwise even if it matches, the subsequent commit
    # would cause conflict.

    $self->svn(['update', $r->name]);

    my $work_path = $self->work_path( $r->name ) ;
    die "no file after backfill" unless -e $work_path;

    return $work_path;
}

sub handle_header {
   my VCP::Dest::svn $self = shift ;

   $self->rev_root( $self->header->{rev_root} )
      unless defined $self->rev_root ;

   $self->create_svn_workspace(
      create_in_repository => 1,
   ) ;

   $self->{SVN_PENDING} = [];
   $self->{SVN_PREV_CHANGE_ID} = undef;

   $self->SUPER::handle_header( @_ ) ;
}


sub handle_rev {
   my VCP::Dest::svn $self = shift ;
   my ( $r ) = @_;

   my $work_path = $self->work_path( $r->name ) ;

   my $change_id = $r->change_id;
   if (@{$self->{SVN_PENDING}} && $change_id ne $self->{SVN_PREV_CHANGE_ID}) {
       debug "commit for ".$self->{SVN_PENDING}[0]->as_string if debugging;
       $self->commit;
       $self->{SVN_PENDING} = [];
       $self->{SVN_PREV_CHANGE_ID} = undef;
   }

   if (defined ($r->action) && $r->action eq 'delete' && !$r->previous_id) {
       debug 'svn is happy with creating on branch'
	   if debugging;

       return;
   }


   if ($r->is_base_rev) {
       my ( $work_path ) = VCP::Revs->fetch_files( $r );
       $self->compare_base_revs( $r, $work_path );

       return;
   }

   $self->{SVN_PREV_CHANGE_ID} = $change_id;
   push @{$self->{SVN_PENDING}}, $r;

#   $r->dest_work_path( $work_path ) ;

}

sub handle_footer {
   my VCP::Dest::svn $self = shift ;

   $self->commit if @{$self->{SVN_PENDING}};
   $self->SUPER::handle_footer ;
}

1;

package VCP::CheapRev;

no strict;

sub AUTOLOAD {
    my $self=shift; $AUTOLOAD =~ s/.*:://;
    $self->{$AUTOLOAD} || $self->{ref}->$AUTOLOAD;
}

sub DESTROY {}

package CleanupEditor;

@ISA = ('SVN::Delta::Editor');
use strict;

sub add_file {
    my $self = shift;
    my ($path, $baton) = @_;
    push @{$self->{to_rm}}, $path
	unless exists $self->{expect}{$path};
}


=head1 AUTHOR

Chia-liang Kao <clkao@clkao.org>

=head1 COPYRIGHT

Copyright (c) 2003 Chia-liang Kao. All rights reserved.

See L<VCP::License|VCP::License> (C<vcp help license>) for the terms of use.

=cut

1
