package Puzzle::Core;

our $VERSION = '0.18';

use 5.008008;
use strict;
use warnings;

use YAML qw(LoadFile);
use Puzzle::Config;
use Puzzle::DBI;
use Puzzle::Null;
use HTML::Mason::Request;
use Log::Any;
use Log::Any::Adapter;

use Params::Validate qw(:types);
use base 'Class::Container';

__PACKAGE__->valid_params(
	cfg_path				=> { parse 	=> 'string', type => SCALAR},
	session					=> { isa 		=> 'Puzzle::Session', optional => 1 },
	lang_manager			=> { isa 		=> 'Puzzle::Lang::Manager' },
	cfg						=> { isa 		=> 'Puzzle::Config'} ,
	tmpl					=> { isa 		=> 'Puzzle::Template'} ,
	dbg						=> { isa 		=> 'Puzzle::Debug'} ,
	args					=> { isa 		=> 'Puzzle::Args'} ,
	post					=> { isa 		=> 'Puzzle::Post'} ,
	sendmail				=> { isa 		=> 'Puzzle::Sendmail'} ,
	crud					=> { isa 		=> 'Puzzle::DBIx::Crud'} ,
	exception				=> { isa 		=> 'Puzzle::Exception'} ,
);

__PACKAGE__->contained_objects (
	session    				=> {class => 'Puzzle::Session', delayed => 1},
	lang_manager			=> 'Puzzle::Lang::Manager',
	cfg						=> 'Puzzle::Config',
	tmpl					=> 'Puzzle::Template',
	dbg						=> 'Puzzle::Debug',
	args					=> 'Puzzle::Args',
	post					=> 'Puzzle::Post',
	page					=> {class => 'Puzzle::Page', delayed => 1},
	sendmail				=> 'Puzzle::Sendmail',
	crud					=> 'Puzzle::DBIx::Crud',
	exception				=> 'Puzzle::Exception',
);


# all new valid_params are read&write methods
use HTML::Mason::MethodMaker(
	read_only 		=> [ qw(cfg_path dbh tmpl lang_manager lang dbg args page 
		sendmail post exception crud) ],
	read_write		=> [ 
		[ cfg 			=> __PACKAGE__->validation_spec->{'cfg'} ],
		[ session		=> __PACKAGE__->validation_spec->{'session'} ],
		[ error			=> { parse 	=> 'string', type => SCALAR} ],
	]
);

*db = \&dbh;

sub new {
	my $class 	= shift;
	# append parameters required for new contained objects loading them
	# from YAML config file
	my $cfgH		= LoadFile($_[1]);
	my @params	= qw(frames base frame_bottom_file frame_left_file frame_top_file exception_file
										frame_right_file gids login description keywords db
										namespace debug debug_path cache auth_class traslation mail page);
	foreach (@params){
		push @_, ($_, $cfgH->{$_}) if (exists $cfgH->{$_});
	}
	# initialize class and their contained objects
	my $self 	= $class->SUPER::new(@_);
	$self->_init;
	return $self;
}


sub _init {
	my $self	= shift;

	if ($self->cfg->debug_path) {
		Log::Any::Adapter->set(File => $self->cfg->debug_path);
		$self->{log} = Log::Any->get_logger();
	} else {
		$self->{log} = Puzzle::Null->new;
	}
	# inizializzazione classi delayed
	my $center_class = 'Puzzle::Block';
	if ($self->cfg->page) {
		$center_class = $self->cfg->page->{center} if (exists $self->cfg->page->{center});
	}
	$self->{page} = $self->create_delayed_object('page',center_class => $center_class);
	$self->_autohandler_once;
}

sub _autohandler_once {
	my $self	= shift;
	my $session_class = 'Puzzle::Session::Fake';
	$Apache::Request::Redirect::LOG = 0;
	if ($self->cfg->db->{enabled}) {
		$Apache::Session::Store::DBI::TableName = $self->cfg->db->{session_table};
		my $dbi = 'dbi:mysql:database=' . $self->cfg->db->{name} . 
			';host=' . $self->cfg->db->{host};
		$self->{dbh} 	||= new Puzzle::DBI($dbi,$self->cfg->db->{username},
			$self->cfg->db->{password}, $self->cfg->db->{schema});
		$session_class = 'Puzzle::Session';
	}
	# alter session class
	$self->{container}->{contained}->{session}->{class} = $session_class;
	$self->{session} = $self->create_delayed_object('session');
}

sub process_request{
	my $self	= shift;
	my $html;

	local $Puzzle::Core::instance = $self;

	&_mason->apache_req->no_cache(1);
	$self->post->clear;
	$self->args->clear;
	$self->post->_set({$self->_mason->request_args});
	$self->session->load;
	# enable always debug for debug users
	$self->cfg->debug(1) if $self->session->user->isGid('debug');
	$self->dbg->timer_reset if $self->cfg->debug;
	# configure language object
	$self->{lang} = $self->lang_manager->get_lang_obj;
	# and send to templates
	$self->args->lang($self->lang_manager->lang);
	$self->_login_logout;
	$self->page->process;
	if ($self->page->center->direct_output) {
		#$self->log->debug(( caller(0) )[3] . ": Print page WITHOUT frames");
		$html	= $self->page->center->html;
	} else {
		#$self->log->debug(( caller(0) )[3] . ": Print page with frames");
		my $args = {
			frame_bottom		=> $self->page->bottom->body,
			frame_left			=> $self->page->left->body,
			frame_top			=> $self->page->top->body,
			frame_right			=> $self->page->right->body,
			frame_center		=> $self->page->body,
			header_client		=> $self->page->headers,
			body_attributes		=> $self->page->body_attributes,
			%{$self->dbg->all_mason_args},
		};
		$args->{frame_debug} = $self->dbg->sprint if ($self->cfg->debug);
		$self->tmpl->autoDeleteHeader(0);
		$html = $self->tmpl->html($args,$self->cfg->base);
	}
	print $html;
	$self->session->save;
	$self->dbh->storage->disconnect if ($self->cfg->db->{enabled} 
		&& !$self->cfg->db->{persistent_connection});
}

sub _login_logout {
	my $self	= shift;
	if ($self->post->logout) {
		$self->session->auth->logout;
	} elsif ($self->post->user ne '' && $self->post->pass ne '') {
		$self->session->auth->login($self->post->user, $self->post->pass);
	}
}

sub _mason  {
	return HTML::Mason::Request->instance();
}

sub log {
	my $s	= shift;
	return $s->{log};
}


1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Puzzle::Core - The core elements of Puzzle module

=head1 SYNOPSIS

See L<Puzzle> documentation.

=head1 DESCRIPTION

See L<Puzzle> documentation.

=head1 AUTHOR

Emiliano Bruni, E<lt>info@ebruni.it<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Emiliano Bruni

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
