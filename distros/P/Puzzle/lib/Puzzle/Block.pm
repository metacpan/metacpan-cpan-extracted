package Puzzle::Block;

our $VERSION = '0.17';

use Params::Validate qw(:types);
use base 'Class::Container';

use HTML::Mason::Exceptions;

use HTML::Mason::MethodMaker(
	read_only			=> [qw(isa_error direct_output)],
	read_write		=> [ 
		 'html',
		[ headers		=> { parse 	=> 'string', type => SCALAR|UNDEF, default => ''} ],
		[ body			=> { parse 	=> 'string', type => SCALAR|UNDEF, default => ''} ],
		[ title			=> { parse 	=> 'string', type => SCALAR|UNDEF, default => ''} ],
		[ body_attributes	=> { parse 	=> 'string', type => SCALAR|UNDEF, default => ''} ],
		[ comp	 		=> { isa => 'HTML::Mason::Component' } ],
	]
);

sub comp_path {
	my $self	= shift;
	my $m	= $self->container->container->_mason;
	if (@_) {
		# reset component
		undef $self->{comp};
		$self->{comp_path} = shift;
		$m->comp_exists($self->{comp_path}) && 
			$self->comp($m->fetch_comp($self->{comp_path}));
	}
	return $self->{comp_path}
}

sub process {
	my $self		= shift;
	my $puzzle	= $self->container->container;
	my $tmpl		= $puzzle->tmpl;
	$self->reset;
	unless ($self->comp) {
		$self->body("Unable to find <b>" . $self->comp_path . "</b> file");
		return;
	}
	# voglio anche l'header
	$tmpl->autoDeleteHeader(0);
	$self->html($self->get_html);
	# ora mi estraggo gli header e li rimuovo
	$tmpl->autoDeleteHeader(1);
	$tmpl->tmplfile(\$self->html);
	$self->body($tmpl->output);
	my $headers = $tmpl->header_css . $tmpl->header_js;
	# add meta refresh if present
	my $metas = $tmpl->header_tokens->{meta};
	my $metaf = q/http-equiv\s*=\s*"\s*refresh\s*"/;
	map {($_->[0] =~ /$metaf/) && ($headers .= $_->[0])} @$metas;
	$self->headers($headers);
}

sub process_as_center {
	my $self	= shift;
	my $puzzle	= $self->container->container;
	my $tmpl		= $puzzle->tmpl;
	my $m				= $puzzle->_mason;
	$self->reset;
	# recupero l'intero blocco html in vari modi
	$tmpl->autoDeleteHeader(0);
	# ottengo, in qualche modo, la pagina html con il body
	eval {$self->html($self->get_html)};
	if ($@) {
		# c'e' un errore
		if ( isa_mason_exception($@) &&
			!isa_mason_exception($@, 'Abort') &&
			!isa_mason_exception($@, 'Decline')) { 
			if ($puzzle->error ne '') {
				# se ho definito questa variabile, allora e'
				# un errore mio e mostro questo come html
				# altrimenti uso quello di default
				$self->html($puzzle->error);
			} else {
				$self->html($@->as_html); 
			}
		} else {
			# e' un errore mason
			$self->html($@);
#			print Data::Dumper::Dumper($self->html);
			$self->{isa_error} = 1;
			return;
		}
	} else {
		$self->{isa_error} = 0;
	}
	if( ($m->apache_req->content_type ne '' && 
			lc($m->apache_req->content_type) ne 'text/html') 	
			|| ($self->html =~/<[fF][Rr][Aa][Mm][Ee][Ss][Ee][Tt]/) )
	{
		# risultato non di tipo html...output diretto oppure
		# pagina con frame...output diretto
		$self->{direct_output} = 1;
		return;
	}
	# tutto regolare...procedo
	# rimuovo l'header
	$tmpl->autoDeleteHeader(1);
	#my $pippo = $self->html;
	$tmpl->tmplfile(\$self->html);
	$self->body($tmpl->output);
	#altero la configurazione sulla base delle informazioni 
	# eventualmente presenti nell'<HEAD> dell'HTML
	$self->alterConfig($nextComp);
	$self->headers($tmpl->header_css  . $tmpl->header_js);
	$self->body_attributes($tmpl->body_attributes);
  $self->title($tmpl->header_tokens->{title}->[0]->[1])
}

sub process_as_login {
	my $self		= shift;
	my $puzzle	= $self->container->container;
	my $tmpl		= $puzzle->tmpl;
	unless ($self->comp) {
		#$self->body("Login file in <b>" . $puzzle->cfg->login . "</b> not found");
		$puzzle->args->set({'exception.cod' => "Login file not found",
			'exception.descr' => "Login file in <b>" . $puzzle->cfg->login . 
			"</b> not found"});
		$puzzle->exception->print;
		return;
	}
	$tmpl->autoDeleteHeader(0);
	$puzzle->args->page($ENV{SCRIPT_NAME});
	$puzzle->args->group(join(' or ',@{$puzzle->cfg->gids} ));
	$self->html($self->get_html);
  # rimuovo l'header
  $tmpl->autoDeleteHeader(1);
	$tmpl->tmplfile(\$self->html);
	$self->body($tmpl->output);
}

sub alterConfig() {
	my $self								= shift;
	my $puzzle							= $self->container->container;
	my $tmpl								= $puzzle->tmpl;
	# recupero i token nell'header
	my $htokens							= $tmpl->header_tokens;
	# recupero dall'header del body i tags meta
	my $metatags 						= $htokens->{meta};
	# cerco tra i vari metatag quelli interessanti
	foreach (@{$metatags}) {
		if ($_->[0] =~m|
							[Nn][Aa][Mm][Ee]\s*=\s*
							"(.*?)"			# solo i tag mcs_*
							\s+[Cc][Oo][Nn][Tt][Ee][Nn][Tt]\s*=\s*
							"(.*?)"				# ne estraggo il valore
						|x) {
			if (exists $puzzle->cfg->{$1} && $1 eq 'gids') {
				# array
				#	if (ref($puzzle->cfg->{$1}) eq 'ARRAY') {
								#		# gia' un array
								#		push @{$puzzle->cfg->{$1}},$2;
								#	} else {
								#			# trasformo in array
								#	my $scalar_value	= $puzzle->cfg->{$1};
								#		$puzzle->cfg->{$1} = [$scalar_value,$2];
								#	}
				$puzzle->cfg->gids([$2]);
			} else {
				$puzzle->cfg->{$1}				= $2;	
			}
		}
	}
	foreach (keys %{$puzzle->cfg}) {
		if (eval {$self->comp->attr($_)} ne '') {
			# vedo se esiste un attributo nella
			# pagina che si chiama come il metacod, se esiste
			# lo imposto e questa cosa prevale sull'eventuale
			# impostazione del metacod nell'HTML della pagina
			$puzzle->cfg->{$_} = $self->comp->attr($_);
		}
	}
}

sub get_html {
	my $self			= shift;
	my $puzzle		= $self->container->container;
	my $tmpl			= $puzzle->tmpl;
	my $m					= $puzzle->_mason;
  my $filePath 	= $self->comp->path;
  my $fileName 	= $self->comp->name;
  return $m->scomp($self->comp,%{$m->request_args}) if ($fileName eq 'autohandler');
	my $ret				= '';
  if ($fileName 	=~ /.+\.m{0,1}pl$/i) {
		# decido che al componente passo solo ARGS
		# le altre cose le deve recuperare in altro modo
   	$ret       	= $m->scomp($self->comp,%{$m->request_args});
		if( $m->apache_req->content_type ne '' && 
			lc($m->apache_req->content_type) ne 'text/html') 
		{		
			# non e' una pagina html...ritorno subito;
			return $ret;	
		}
	} elsif ($fileName 	=~ /.+\.mplcom$/i) {
  	return $m->call_next;
  } elsif ($ret eq '') {
		# alla pagina statica passo tutti i parametri %as
		# piu' tutti i parametri di sessione
		# piu' tutti gli userdata
		$ret    			= $tmpl->mhtml(undef,$filePath);
   }
	return $ret;
}

sub reset {
	my $s	= shift;
	$s->{direct_output} = 0;
	$s->{isa_error} = 0;
}

1;
