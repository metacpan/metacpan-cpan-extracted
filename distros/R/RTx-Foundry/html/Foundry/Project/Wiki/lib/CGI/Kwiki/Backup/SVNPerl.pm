package CGI::Kwiki::Backup::SVNPerl;
$VERSION = '0.01';

use strict;
use base 'CGI::Kwiki::Backup::SVN';
use File::Spec;
use SVN::Core '0.31';
use SVN::Repos;
use SVN::Fs;
use SVN::Delta;
use SVN::Simple::Edit;
use Text::Diff ();

use constant SVN_DIR => 'metabase/svn';

my $user_name = '';

my ($repos, $fs, $pool, $init);

sub init {
    my $self = shift;
    $pool = SVN::Pool->new_default;

    my $svn_repo = ($self->config->exists ('svn_repo')) ?
                   $self->config->svn_repo :
                   SVN_DIR;

    my $need_init_pages = 0;
    if (-d $svn_repo) {
	$repos = SVN::Repos::open ($svn_repo);

        if ($self->config->exists ("svn_path")) {
            my $root = $repos->fs->revision_root ($repos->fs->youngest_rev);
            if ($root->check_path ($self->config->svn_path)
                == $SVN::Node::none) {
                $need_init_pages = 1;
            }
        }
    }
    else {
	$repos = SVN::Repos::create($svn_repo, undef, undef, undef, undef);
        $need_init_pages = 1;
    }

    if ($need_init_pages) {
	my $edit = $self->_get_root_edit ('kwiki-install', 'kwiki install');

	$edit->open_root (0);

        for my $page_id ($self->database->pages) {
            my $repo_page_id = $self->_convert_to_repo_page_id ($page_id);
	    $edit->add_file ($repo_page_id);
	    open my $fh, $self->database->file_path($page_id);
	    $edit->modify_file ($repo_page_id, $fh)
	}
	$edit->close_edit;
    }
    $fs = $repos->fs;
    ++$init;
}

sub new {
    my ($class) = shift;
    my $self = $class->SUPER::new(@_);
    $self->init unless $init;
    $self->{pool} = SVN::Pool->new_default_sub();

    $self->{headrev} = $fs->youngest_rev;

    return $self;
}

sub _get_root_edit {
    my ($self, $author, $comment, $pool) = @_;
    SVN::Simple::Edit->new (_editor => [SVN::Repos::get_commit_editor
					($repos, '', '/', $author,
					 $comment, sub {})],
			    pool => $pool || SVN::Pool->new ($pool));
}

sub _get_edit {
    my ($self, $author, $comment, $pool) = @_;
    my $path_root = ($self->config->exists ("svn_path")) ?
        $self->config->svn_path :
        '/';
    SVN::Simple::Edit->new (_editor => [SVN::Repos::get_commit_editor
					($repos, '', $path_root, $author,
					 $comment, sub {})],
			    pool => $pool || SVN::Pool->new ($pool));
}

sub _convert_to_repo_page_id {
    my ($self, $page_id) = @_;

    return ($self->config->exists ("svn_path")) ?
        $self->config->svn_path . "/" . $page_id :
        $page_id;
}

sub commit {
    my ($self, $page_id) = @_;
    my $edit = $self->_get_edit ($user_name || $self->metadata->edit_by, '',
				 $self->{pool});
    $edit->open_root ($self->{headrev});
    if ($self->database->exists ($page_id)) {
	open my $fh, $self->database->file_path ($page_id);
	$edit->modify_file ($self->has_history ($page_id) ?
			    $edit->open_file ($page_id) :
			    $edit->add_file ($page_id),
			    $fh);
    }
    else {
	$edit->delete_entry ($page_id);
    }

    $edit->close_edit();
}

sub has_history {
    my ($self, $page_id) = @_;
    $page_id ||= $self->cgi->page_id;

    my $root = $fs->revision_root($self->{headrev});

    my $repo_page_id = $self->_convert_to_repo_page_id ($page_id);

    SVN::Fs::check_path($root, $repo_page_id) == $SVN::Core::node_file;
}

sub history {
    my ($self, $page_id) = @_;
    $page_id ||= $self->cgi->page_id;
    return [] unless $page_id;

    my $repo_page_id = $self->_convert_to_repo_page_id ($page_id);

    my $revs;

    my $hist =
        $fs->revision_root ($fs->youngest_rev)->node_history ($repo_page_id);

    while ($hist = $hist->prev (0)) {
	push @$revs, ($hist->location)[1];
    }

    my $history = [map {
	{ revision => $_,
	  edit_by => $fs->revision_prop($_, 'svn:author'),
	  date => $fs->revision_prop($_, 'svn:date')}} @$revs];

    return $self->_build_history($history);
}

sub fetch {
    my ($self, $page_id, $revision) = @_;
    my $root = $fs->revision_root($revision || $self->{headrev});

    my $repo_page_id = $self->_convert_to_repo_page_id ($page_id);

    my $stream = SVN::Fs::file_contents($root, $repo_page_id);
    local $/;
    my $log = <$stream>;
    utf8::decode($log) if defined &utf8::decode;
    return $log;
}

sub diff {
    my ($self, $page_id, $r1, $r2, $context) = @_;

    my $root1 = $fs->revision_root ($r1);
    my $root2 = $fs->revision_root ($r2);

    my $repo_page_id = $self->_convert_to_repo_page_id ($page_id);

    Text::Diff::diff(SVN::Fs::file_contents($root1, $repo_page_id),
		     SVN::Fs::file_contents($root2, $repo_page_id),
		     { STYLE => "Unified" });
}

1;
