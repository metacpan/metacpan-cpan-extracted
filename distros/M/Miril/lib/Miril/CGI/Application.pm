package Miril::CGI::Application;

use strict;
use warnings;
use autodie;

use Try::Tiny;
use Exception::Class;

use base 'CGI::Application';

use CGI::Application::Plugin::Authentication;
use CGI::Application::Plugin::Redirect;
use CGI::Application::Plugin::Forward;
use Module::Load;
use File::Spec::Functions qw(catfile);
use Data::AsObject qw(dao);
use Data::Page;
use Ref::List qw(list);
use Miril;
use Miril::Exception;
use Miril::Theme::Flashyweb;
use Miril::View;
use Miril::InputValidator;
use Miril::Publisher;
use File::Copy qw(copy);
use Number::Format qw(format_bytes);
use POSIX qw(strftime);
use Syntax::Keyword::Gather qw(gather take);

### ACCESSORS ###

use Object::Tiny qw(
	view
	user_manager
	miril
	validator
);

### SETUP ###

sub setup {
	my $self = shift;

	# setup runmodes

    $self->mode_param('action');
    $self->run_modes(
    	'list'         => 'posts_list',
        'edit'         => 'posts_edit',
        'create'       => 'posts_create',
        'delete'       => 'posts_delete',
        'view'         => 'posts_view',
        'update'       => 'posts_update',
		'publish'      => 'posts_publish',
		'files'        => 'files_list',
		'upload'       => 'files_upload',
		'unlink'       => 'files_delete',
		'search'       => 'search',
		'login'        => 'login',
		'logout'       => 'logout',
		'account'      => 'account',
	);

	$self->start_mode('list');
	$self->error_mode('error');

	# setup miril
	my $miril_dir = $self->param('miril_dir');
	my $site = $self->param('site');
	$self->{miril}= Miril->new($miril_dir, $site);
	
	# configure authentication
	try {
		my $user_manager_name = "Miril::UserManager::" . $self->miril->cfg->user_manager;
		load $user_manager_name;
		$self->{user_manager} = $user_manager_name->new($self->miril);
	} catch {
		Miril::Exception->throw(
			errorvar => $_,
			message  => 'Could not load user manager',
		);
	};

	$self->authen->config( 
		DRIVER         => [ 'Generic', $self->user_manager->verification_callback ],
		LOGIN_RUNMODE  => 'login',
		LOGOUT_RUNMODE => 'logout',
		CREDENTIALS    => [ 'authen_username', 'authen_password' ],
		STORE          => [ 'Cookie', SECRET => $self->miril->cfg->secret, EXPIRY => '+30d', NAME => 'miril_authen' ],
	);

	$self->authen->protected_runmodes(':all');


	# load view
	$self->{view} = Miril::View->new(
		theme            => Miril::Theme::Flashyweb->new,
		is_authenticated => $self->authen->is_authenticated,
		latest           => $self->miril->store->get_latest,
		miril            => $self->miril,

	);

	$self->{validator} = Miril::InputValidator->new;
	$self->header_add( -type => 'text/html; charset=utf-8');

}

### RUN MODES ###

sub error {
	my ($self, $e) = @_;

	my @error_stack;

	if ($e->isa('Miril::Exception')) {
		warn $e->errorvar;
	} elsif ($e->isa('autodie::exception')) {
		warn $e;
		$e = Miril::Exception->new(
			message  => "Unspecified error",
			errorvar => $e->stringify,
		);
	} else {
		warn $e;
		$e = Miril::Exception->new(
			message  => "Unspecified error",
			errorvar => $e,
		);
	}
	$self->view->{fatal} = $e;
	my $tmpl = $self->view->load('error');
	return $tmpl->output;
}

sub posts_list {
	my $self = shift;
	my $q = $self->query;

	my @posts = $self->miril->store->get_posts(
		author => ( $q->param('author') or undef ),
		title  => ( $q->param('title' ) or undef ),
		type   => ( $q->param('type'  ) or undef ),
		status => ( $q->param('status') or undef ),
		topic  => ( $q->param('topic' ) or undef ),
	);

	my @current_posts = $self->_paginate(@posts);
	
	my $tmpl = $self->view->load('list');
	$tmpl->param('posts', {list => \@current_posts});
	return $tmpl->output;

}

sub search {
	my $self = shift;

	my $cfg = $self->miril->cfg;

	my $tmpl = $self->view->load('search');

	$tmpl->param('statuses', $self->_prepare_statuses );
	$tmpl->param('types',    $self->_prepare_types    );
	$tmpl->param('topics',   $self->_prepare_topics   ) if $cfg->topics->list;
	$tmpl->param('authors',  $self->_prepare_authors  ) if $cfg->authors->list;

	return $tmpl->output;
}

sub posts_create {
	my $self = shift;

	my $cfg = $self->miril->cfg;

	my $empty_post;

	$empty_post->{statuses} = $self->_prepare_statuses;
	$empty_post->{types}    = $self->_prepare_types;
	$empty_post->{authors}  = $self->_prepare_authors if $cfg->authors->list;
	$empty_post->{topics}   = $self->_prepare_topics  if $cfg->topics->list;

	my $tmpl = $self->view->load('edit');
	$tmpl->param('post', $empty_post);
	
	return $tmpl->output;
}

sub posts_edit {
	my ($self, $invalid_id) = @_;

	my $cfg = $self->miril->cfg;
	my $q = $self->query;
	my $post;

	if ($invalid_id) {
		my %cur_topics;
		if ($q->param('topic')) {
			%cur_topics = map {$_ => 1} $q->param('topic');
		}
		$post = dao {
			id       => $q->param('id'),
			old_id   => $q->param('old_id'),
			source   => $q->param('source'),
			title    => $q->param('title'),
			authors  => $self->_prepare_authors($q->param('author')),
			topics   => $self->_prepare_topics(%cur_topics),
			statuses => $self->_prepare_statuses($q->param('status')),
			types    => $self->_prepare_types($q->param('type')),
		};
		use Data::Dumper;
		warn Dumper $post;
	} else {
		#TODO check if $post is defined
		$post = $self->miril->store->get_post($q->param('id'));
	
		my %cur_topics;

		#FIXME
		if ( list $post->topics ) 
		{
			%cur_topics = map {$_->id => 1} list $post->topics;
		}
	
		$post->{authors}  = $self->_prepare_authors($post->author) if $cfg->authors->list;
		$post->{topics}   = $self->_prepare_topics(%cur_topics)    if $cfg->topics->list;
		$post->{statuses} = $self->_prepare_statuses($post->status);
		$post->{types}    = $self->_prepare_types($post->type->id);
	}

	my $tmpl = $self->view->load('edit');
	$tmpl->param('post', $post);
	$tmpl->param('invalid', $self->param('invalid'));

	$self->miril->store->add_to_latest($post->id, $post->title);

	return $tmpl->output;
}

sub posts_update {
	my $self = shift;
	my $q = $self->query;

	my $invalid = $self->validator->validate({
		id      => 'text_id required',
		author  => 'line_text',
		status  => 'text_id',
		source  => 'paragraph_text',
		title   => 'line_text required',
		type    => 'text_id required',
		old_id  => 'text_id',
	}, $q->Vars);
	
	if ($invalid) {
		$self->param('invalid', $invalid);
		return $self->forward('edit', $q->param('old_id'));
	}

	my %post = (
		'id'     => $q->param('id'),
		'author' => ( $q->param('author') or undef ),
		'status' => ( $q->param('status') or undef ),
		'source' => ( $q->param('source') or undef ),
		'title'  => ( $q->param('title')  or undef ),
		'type'   => ( $q->param('type')   or undef ),
		'old_id' => ( $q->param('old_id') or undef ),
	);

	# SHOULD NOT BE HERE
	$post{topics} = [$q->param('topic')] if $q->param('topic');

	$self->miril->store->save(%post);

	return $self->redirect("?action=view&id=" . $post{id});
}

sub posts_delete {
	my $self = shift;

	my $id = $self->query->param('old_id');
	$self->miril->store->delete($id);

	return $self->redirect("?action=list");
}

sub posts_view {
	my $self = shift;
	
	my $q = $self->query;
	my $id = $q->param('old_id') ? $q->param('old_id') : $q->param('id');

	my $post = $self->miril->store->get_post($id);
	if ($post) {
		$post->{body} = $post->body;

		my $tmpl = $self->view->load('view');
		$tmpl->param('post', $post);
		return $tmpl->output;
	} else {
		return $self->redirect("?action=list");	
	}
}

sub login {
	my $self = shift;
	
	my $tmpl = $self->view->load('login');
	return $tmpl->output;
}

sub logout {
	my $self = shift;

	$self->authen->logout();
	
	return $self->redirect("?action=login");
}

sub account 
{
	my $self = shift;
	my $q = $self->query;

	if ( $q->param('name') or $q->param('new_password') ) 
	{
	
		my $username        = $q->param('username');
		my $name            = $q->param('name');
		my $new_password    = $q->param('new_password');
		my $retype_password = $q->param('retype_password');
		my $password        = $q->param('password');

		my $user = $self->user_manager->get_user($username);
		my $encrypted = $self->user_manager->encrypt($password);

		unless ( ($user->{password} eq $password) or ($user->{password} eq $encrypted) )
		{
			$self->miril->push_warning( 
				message => 'Wrong existing password!',
				errorvar => '',
			);
			return $self->redirect("?action=account") 
		}

		$user->{name} = $name;
		if ( $new_password and ($new_password eq $retype_password) ) {
			$user->{password} = $self->user_manager->encrypt($new_password);
		}
		$self->user_manager->set_user($user);
		return $self->redirect("?"); 


	} else {
	
		my $username = $self->authen->username;
		my $user = $self->user_manager->get_user($username);

		my $tmpl = $self->view->load('account');
		$tmpl->param('user', $user);
		return $tmpl->output;
	} 
}

sub files_list {
	my $self = shift;

	my $cfg = $self->miril->cfg;

	my $files_path = $cfg->files_path;
	my $files_http_dir = $cfg->files_http_dir;
	my @files;
	
	try {
		opendir(my $dir, $files_path);
		@files = grep { -f catfile($files_path, $_) } readdir($dir);
		closedir $dir;
	} catch {
		Miril::Exception->throw(
			errorvar => $_,
			message  => 'Could not read files directory',
		);
	};

	my @current_files = $self->_paginate(@files);

	my @files_with_data = gather 
	{ 
		for my $file (@current_files)
		{
			my $filepath = catfile($files_path, $file);
			my @modified = localtime( time() - ( (-M $filepath) * 60 * 60 * 24 ) );

			take {
				name     => $file, 
				href     => $files_http_dir . $file, 
				size     => format_bytes( -s $filepath ), 
				modified => strftime( "%d/%m/%Y %H:%M", @modified), 
			};
		}
	};

	my $tmpl = $self->view->load('files');
	$tmpl->param('files', \@files_with_data);
	return $tmpl->output;
}

sub files_upload {
	my $self = shift;
	my $q = $self->query;
	my $cfg = $self->miril->cfg;

	if ( $q->param('file') or $q->upload('file') ) {
	
		my @filenames = $q->param('file');
		my @fhs = $q->upload('file');

		for ( my $i = 0; $i < @fhs; $i++) {

			my $filename = $filenames[$i];
			my $fh = $fhs[$i];

			if ($filename and $fh) {
				my $new_filename = catfile($cfg->files_path, $filename);
				try {
					my $new_fh = IO::File->new($new_filename, "w");
					copy($fh, $new_fh);
					$new_fh->close;
				} catch {
					Miril::Exception->throw(
						errorvar => $_,
						message  => 'Could not upload file',
					);
				}
			}
		}

		return $self->redirect("?action=files");

	} else {
		my $tmpl = $self->view->load('upload');
		return $tmpl->output;
	}
}

sub files_delete {
	my $self = shift;	
	my $cfg = $self->miril->cfg;
	my $q = $self->query;

	my @filenames = $q->param('file');

	try {
		for (@filenames) {
			try { 
				unlink( catfile($cfg->files_path, $_) ) 
			} catch {
				Miril::Exception->throw(
					errorvar => $_,
					message  => 'Could not delete file',
				);
			};
		}
	};

	return $self->redirect("?action=files");
}

sub posts_publish {
	my $self = shift;

	my $cfg = $self->miril->cfg;
	
	my $do = $self->query->param("do");
	my $rebuild = $self->query->param("rebuild");

	if ($do) {
		Miril::Publisher->publish($self->miril, $rebuild);
		return $self->redirect("?action=list");
	} else {
		my $tmpl = $self->view->load('publish');
		return $tmpl->output;
	}
}

### PRIVATE METHODS ###

# form generation utilities: this stuff is ugly, should be replaced with HTML::FillInForm::Lite

sub _prepare_authors {
	my ($self, $selected) = @_;
	my $cfg = $self->miril->cfg;
	my @authors;
	if ($selected) {
		@authors = map {{ name => $_, id => $_ , selected => $_ eq $selected }} $cfg->authors->list;
	} else {
		@authors = map {{ name => $_, id => $_  }} $cfg->authors->list;
	}
	return \@authors;
}

sub _prepare_statuses {
	my ($self, $selected) = @_;
	my $cfg = $self->miril->cfg;
	my @statuses;
	if ($selected)
	{
		@statuses = map {{ name => $_, id => $_, selected => $_ eq $selected }} $cfg->statuses->list;
	}
	else
	{
		@statuses = map {{ name => $_, id => $_ }} $cfg->statuses->list;
	}
	return \@statuses;
}

sub _prepare_topics {
	my ($self, %selected) = @_;
	my $cfg = $self->miril->cfg;
	if (%selected)
	{
		my @topics = map {{ name => $_->name, id => $_->id, selected => $selected{$_->id} }} $cfg->topics->list;
		return \@topics;
	}
	else
	{
		my @topics = map {{ name => $_->name, id => $_->id, }} $cfg->topics->list;
		return \@topics;
	}
}

sub _prepare_types {
	my ($self, $selected) = @_;
	my $cfg = $self->miril->cfg;
	my @types;
	if ($selected)
	{
		@types = map {{ name => $_->name, id => $_->id, selected => $_->id eq $selected }} $cfg->types->list;
	}
	else 
	{
		@types = map {{ name => $_->name, id => $_->id }} $cfg->types->list;
	}
	return \@types;
}

# pagination: needs to be abstracted so that different UI's (e.g. Mojo) could use it 

sub _paginate {
	my $self = shift;
	my @posts = @_;
	
	my $cfg = $self->miril->cfg;

	return unless @posts;

	if (@posts > $cfg->posts_per_page) {

		my $page = Data::Page->new;
		$page->total_entries(scalar @posts);
		$page->entries_per_page($cfg->posts_per_page);
		$page->current_page($self->query->param('page_no') ? $self->query->param('page_no') : 1);
		
		my $pager;
		
		if ($page->current_page > 1) {
			$pager->{first}    = $self->_generate_paged_url($page->first_page);
			$pager->{previous} = $self->_generate_paged_url($page->previous_page);
		}

		if ($page->current_page < $page->last_page) {
			$pager->{'last'} = $self->_generate_paged_url($page->last_page);
			$pager->{'next'} = $self->_generate_paged_url($page->next_page);
		}

		$self->view->{pager} = $pager;
		return $page->splice(\@posts);

	} else {
		return @posts;
	}
}

sub _generate_paged_url {
	my $self = shift;
	my $page_no = shift;

	my $q = $self->query;

	my $paged_url = '?action=' . $q->param('action');

	if (
		$q->param('title')  or
		$q->param('author') or
		$q->param('type')   or
		$q->param('status') or
		$q->param('topic')
	) {
		$paged_url .=   '&title='  . $q->param('title')
		              . '&author=' . $q->param('author') 
		              . '&type='   . $q->param('type') 
		              . '&status=' . $q->param('status')
		              . '&topic='  . $q->param('topic');
	}

	$paged_url .= "&page_no=$page_no";

	return $paged_url;
}

1;
