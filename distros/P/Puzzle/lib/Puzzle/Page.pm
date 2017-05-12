package Puzzle::Page;

our $VERSION = '0.02';

use Params::Validate qw(:types);
use base 'Class::Container';
__PACKAGE__->valid_params(
	bottom	=> { isa 		=> 'Puzzle::Block'} ,
	center	=> { isa 		=> 'Puzzle::Block'} ,
	left		=> { isa 		=> 'Puzzle::Block'} ,
	right		=> { isa 		=> 'Puzzle::Block'} ,
	top			=> { isa 		=> 'Puzzle::Block'} ,
);

__PACKAGE__->contained_objects (
	bottom	=> { class => 'Puzzle::Block', delayed => 0 },
	center	=> 'Puzzle::Block',
	left		=> { class => 'Puzzle::Block', delayed => 0 },
	right		=> { class => 'Puzzle::Block', delayed => 0 },
	top			=> { class => 'Puzzle::Block', delayed => 0 },
);


# all new valid_params are read&write methods
use HTML::Mason::MethodMaker(
	read_only 		=> [ qw(bottom center left right top) ],
);

sub process {
	my $self			= shift;
	my $puzzle		= $self->container;
	my $m					= $puzzle->_mason;
#	$self->container->post->_set({$self->container->_mason->request_args});
	my $nextComp 	= $m->fetch_next;
	#$puzzle->log->debug(( caller(0) )[3] . ": component " . $nextComp->path);
	if (eval {$nextComp->attr('gid')} &&
		$self->container->cfg->gids($nextComp->attr('gids')) &&
		!$puzzle->session->auth->check) {
		# l'utente non ha accesso alla pagina. Mostro la pagina di login
		$self->_show_login;
		$self->center->process_as_login;
	} else {
		# accesso alla pagina consentito
		$self->center->comp($nextComp);
		$self->center->process_as_center;
		if ($self->center->isa_error) {
			$self->container->session->save;
			# visto che e' un errore mason, lo rilancio
			HTML::Mason::Exceptions::rethrow_exception($self->center->html);
			return;
		} elsif ($self->center->direct_output) {
			# interrompo tutto
			return;
		}
	}
	# SE SERVE, RIVALIDO l'UTENTE
	# VALUTARE SE LE DUE VERIFICHE QUI E PRIMA NON SI POSSANO INGLOBARE IN
	# UNA UNICA
	unless ($puzzle->session->auth->check) {
		# l'utente non ha accesso alla pagina. Mostro la pagina di login
		$self->center->comp_path($puzzle->cfg->login);
		$self->center->process_as_login;
	}
	if ($puzzle->cfg->frames && 
		$puzzle->args->print ne '1' && $puzzle->cfg->base) {
		#@$puzzle->log->debug(( caller(0) )[3] . ": Print page with frames");
		foreach (qw/top left right bottom/) {
			if ($puzzle->cfg->{"frame_${_}_file"} ne '') {
				$self->$_->comp_path($puzzle->cfg->{"frame_${_}_file"});
				$self->$_->process;
			}
		}
	} else {
		#$puzzle->log->debug(( caller(0) )[3] . ": Set page without frames because: cfg->frames is " .
		#	$puzzle->cfg->frames . " and args->print is " . $puzzle->args->print . " and cfg->base is " .
		#	$puzzle->cfg->base);
		$self->center->{direct_output} = 1;
	}
}

sub body {
	my $self		= shift;
	return $self->center->body;
}

sub headers {
	my $self		= shift;
	my $ret			= '';
	my @frames	= qw/center top left right bottom/;
	foreach (@frames) {
		$ret	.= $self->$_->headers;
	}
	return $ret;
}

sub body_attributes {
	my $self		= shift;
	return $self->center->body_attributes;
}

sub title {
	my $self		= shift;
	return $self->center->title;
}

sub _show_login {
	my $self		= shift;
	my $puzzle	= $self->container;
	#$puzzle->args->page($ENV{SCRIPT_NAME});
	#$puzzle->args->group(join(' oppure ',@{$puzzle->cfg->gids} ));
	$self->center->comp_path($puzzle->cfg->login);
}
1;
