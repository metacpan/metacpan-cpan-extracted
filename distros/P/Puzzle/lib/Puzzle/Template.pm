package Puzzle::Template;

our $VERSION = '0.18';

use base qw(Class::Container HTML::Template::Pro::Extension);

use File::Spec;
use Params::Validate qw(:types);

use Puzzle::DBIx::ClassConverter;


__PACKAGE__->valid_params(
	dcc					=> { isa	=> 'Puzzle::DBIx::ClassConverter'} ,
);

__PACKAGE__->contained_objects (
	dcc		=> 'Puzzle::DBIx::ClassConverter',
);

use HTML::Mason::MethodMaker(
	read_only 		=> [ qw(dcc) ],
);

*print_template = \&print;

# definition of localizated error string for unexistent template
my $err_tmpl_notfound_string = {
	'it' => q|
				<h2>Modello per il componente <b>%comp_name%</b> 
				non trovato.</h2>
						Il modello mancante dovrebbe essere posto 
						nel percorso <br><b><pre>%tmpl_file_path%</pre></b>
				<p>Contattate il webmaster
			|,
	'en' => q|
				<h2>Unable to find template for <b>%comp_name%</b> 
				.</h2>
						The missing template should be located in the path
						<br><b><pre>%tmpl_file_path%</pre></b>
				<p>Please contact webmaster
			|,
	'fr' => q|
				<h2>Unable to find template for <b>%comp_name%</b> 
				.</h2>
						The missing template should be located in the path
						<br><b><pre>%tmpl_file_path%</pre></b>
				<p>Please contact webmaster
				<p>Please traslate it in french language
			|,
};

my %fields =
    (
			plugins	=> ['SLASH_VAR','HEAD_BODY'],
     );


sub new {
	my $class = shift;
	my %opt		= @_;
	# first call the Class::Container::new
	my $htmpl = $class->SUPER::new();
	# then create an initial HTML::Template::Pro::Extension object
	my $htmpl1 = new HTML::Template::Pro::Extension(
		%fields, functions => {
								date2human => \&_ext_date2human,
								datetime2human => \&_ext_datetime2human,
								isgid => \&_ext_isgid,
								s			=> \&_ext_s
							}
	);
	# then merge the two objects and bless them to this class
	$htmpl = bless {%$htmpl,%$htmpl1}, $class;
	$htmpl->file($opt{file}) if (exists($opt{file}));	
	$htmpl->cache($opt{cache}) if (exists($opt{cache}));	
	return $htmpl;
}

sub cache {defined $_[1] ? $_[0]->{cache} = $_[1] : $_[0]->{cache};}

sub print {
  my $self  = shift;
  print $self->sprint(@_);
}

sub sprint {
  my $self      = shift;
  my $args      = shift || {};
  my $tmpl_file_path  = shift || $self->container->_mason->current_comp->name;
  $tmpl_file_path   = $self->_convFileName($tmpl_file_path);
  # merging $c_args and items
  my $html      = $self->html($args,$tmpl_file_path);
  return $html  if (defined $html);
}



sub html {
	# overraide defalt html method to support base_root_dir
	# and return html error string if selected template doesn't exist.
	my $self = shift;
	my $args = shift;
	my $file = shift;

	my $as = { %{$self->container->dbg->all_mason_args} ,%$args};

	# define lang bypass cache
	#if (exists($as->{lang})) {
	#	$self->{default_language} = $as->{lang};
	#}
	if (defined $file) {
		my $file 	= $self->_tmplFilePath($file);
		# _tmplFilePath could change all_mason_args
		$as = { %{$self->container->dbg->all_mason_args} ,%$args};
		if (-e $file) {
			$self->SUPER::tmplfile($self->_getTextFile($file));
			return $self->SUPER::html($as,undef);
		} else {
			# template file don't exists...print error to client
			$self->_throw_error_tmpl_notfound($file,$mason);
			# undef to stop print above.
			return undef;
		}
	} else {
		return $self->SUPER::html($as);
	}
}

sub mhtml {
	my $self = shift;
	my $args = shift || {};
	my $file = shift;

	my $as = { %{$self->container->dbg->all_mason_args} ,%$args};
	return $self->html($as,$file);
}

use Switch;

use Data::Dumper;
use JSON::Any;
use XML::Simple;
use Text::CSV::Slurp;

sub printct {
		print $_[0]->sprintct($_[1], $_[2]);
}

sub sprintct {
		my $self	= shift;
		my $pl		= shift;
		# printa una struttura perl, di solito un hashref
		# coerentemente con il tipo di content-type di uscita
		# supportato per ora, text, html, xml, json
		#

		my $ct = shift || $self->container->_mason->apache_req->content_type;

		my $pl2html = sub { return Data::Dumper::Dumper($_[0]) };
		my $pl2text = sub { return Data::Dumper::Dumper($_[0]) };
		my $pl2json = sub { my $obj =  JSON::Any->new; return $obj->objToJson($_[0]) };
		my $pl2xml 	= sub { return XMLout($_[0]) };
		my $pl2csv  = sub { return Text::CSV::Slurp->create(input => $_[0],sep_char => ';') };
		my $pl2else = sub { return Data::Dumper::Dumper($_[0]) };

		my $fc;
		
		switch ($ct) {
			case /json/					{ $fc = $pl2json}
			case /xml/ 					{ $fc = $pl2xml}
			case 'text/plain' 			{ $fc = $pl2text}
			case 'text/html' 			{ $fc = $pl2html}
			case /excel/				{ $fc = $pl2csv}
			else 						{ $fc = $pl2else}
		}

		return &$fc($pl);
}


sub _getTextFile {
	my $self 			= shift;
	my $filename = shift;
	my $ret;
	$ret = $self->container->_mason->cache(namespace=>__PACKAGE__)->get($filename,busy_lock=>'30 sec') 
		if ($self->cache);
	if (!defined($ret) || !$self->cache) {
	confess(__PACKAGE__ . " : Cannot open included file $filename : $!")
	        unless defined(open(TEMPLATE, $filename));
	while (read(TEMPLATE, $ret, 10240, length($ret))) {}
	close(TEMPLATE);
	$self->container->_mason->cache(namespace=>__PACKAGE__)->set($filename, $ret, '5h')
		if ($self->cache);
	}
	return \$ret;
}


sub _tmplFilePath {
	# convert the file path based on absolute/relative path
	# and to base_dir and language
	my $self			= shift;
	my $mason			= $self->container->_mason;
	my $comp_name	= shift || $mason->current_comp->name;
	my $abs_path;
	# built absolute path
	my $base_root	= $mason->interp->comp_root;
	my $tbp			= $self->{template_base_path} eq 'undef' ? '' :
									$self->{template_base_path};
	if (File::Spec->file_name_is_absolute($comp_name)) {
		$abs_path	= File::Spec->catfile($base_root,$tbp,$comp_name);
	} else {
		my $comp_dir=  $mason->current_comp->path;
		(undef,$comp_dir,undef) = File::Spec->splitpath($comp_dir);
		$abs_path	= File::Spec->catfile($base_root,$tbp,$comp_dir,$comp_name);
	}
	return $self->_tmplLang($abs_path);
}

use YAML qw(LoadFile);

sub _tmplLang {
	# try to see if exists file for language selected
	my $self			= shift;
	my $abs_path		= shift;
	#my $lang			= $self->{default_language};
	my $lang			= $self->container->lang_manager->lang;
	my ($volume,$dirs,$file) = File::Spec->splitpath( $abs_path ); 
	my ($fn,$ext) 		= split(/\./,$file);

	# check and load Yaml language file into page
	my $yaml_path		= &_existsPath($volume,$dirs,$fn .  '.yaml');
	if ($yaml_path) {
		$self->container->args->set($self->yamlArgs($yaml_path,$lang));
	}

	my $mobile 			= $self->_isMobile ? '.mobile' : '';

	my $rfile;
	$rfile				= &_existsPath($volume,$dirs,$fn.$mobile.'.'.$lang.'.'.$ext) unless ($yaml_path);
	$rfile				= &_existsPath($volume,$dirs,$fn.$mobile.'.'.$ext)  unless ($rfile);
	$rfile				= &_existsPath($volume,$dirs,$fn.'.'.$ext)  unless ($rfile);

	return $rfile;
}

sub yamlArgs {
	my $self			= shift;
	my $yaml_path		= shift;
	my $lang			= shift;
	my $ts 				= LoadFile($yaml_path);
	&_recursiveStructRemoveLang(\$ts,$lang);
	return $ts;
}

sub _recursiveStructRemoveLang {
	my $struct          = shift;
	my $lang            = shift;

	foreach my $key (keys %$$struct) {
		if (ref($$struct->{$key}) eq 'HASH') {
			_recursiveStructRemoveLang(\($$struct->{$key}),$lang);
		} elsif ($key eq $lang) {
			$$struct = $$struct->{$lang};
			return;
		} 
	}
}

sub _existsPath {
	my ($volume,$dirs,$file) = @_;
	my $path = File::Spec->canonpath(File::Spec->catpath($volume,$dirs,$file));
	return -e $path ? $path : undef;
}

use HTTP::BrowserDetect;

sub _isMobile {
	# detect if browser is mobile
	my $self			= shift;
	my $ua_string       = $ENV{'HTTP_USER_AGENT'};
	my $bdetect         = new HTTP::BrowserDetect($ua_string);
	return $bdetect->mobile;
}

sub _convFileName {
	# convert component name in template file subst extention with ".htt"
	my $self 			= shift;
	my $abs_path        = shift;
	my ($volume,$dirs,$file) = File::Spec->splitpath( $abs_path );
	my ($fn,$ext)       = split(/\./,$file);
	return $abs_path if ($ext !~ /^m(pl|htm|html)$/);
	$file				= "$fn.htt";
	return File::Spec->canonpath(File::Spec->catpath($volume,$dirs,$file));
}

sub _print_html() {
	my $self 	= shift;
	return "<HTML>\n<HEAD>\n</HEAD>\n<BODY>\n" . shift() . "\n</BODY>\n</HTML>";
}

sub _throw_error_tmpl_notfound {
	my $self						= shift;
	my $tmpl_file_path	= shift;
	my $mason 					= shift;
	#my $comp_name				= $mason->callers(0)->path;
	my $comp_name				= $mason->current_comp->path;
	my $htmlerr 				= $self->_print_html($self->_err_tmpl_notfound);
	$self->tmplfile(\$htmlerr);
	print $self->html({	comp_name 			=> $comp_name , 
											tmpl_file_path 	=> $tmpl_file_path} );
}

sub _err_tmpl_notfound {
	# return localized error string for unexistent template
	# see err_tmpl_notfound_string hash in the header of this package
	return exists($err_tmpl_notfound_string->{$self->{default_language}}) ? 
						$err_tmpl_notfound_string->{$self->{default_language}} : 
						$err_tmpl_notfound_string->{en};
}

sub _ext_date2human {
	my @split_date	= _split_date(shift);
	if ($#split_date == 0) {
		# not a date
		return $split_date[0]
	} else {
		# return %d-%m-%Y
		return "$split_date[2]-$split_date[1]-$split_date[0]";
	}
}

sub _ext_datetime2human {
	my @split_date	= _split_date(shift);
	if ($#split_date == 0) {
		# not a date
		return $split_date[0]
	} else {
		# return %d-%m-%Y
		return "$split_date[2]-$split_date[1]-$split_date[0] $split_date[3]:$split_date[4]";
	}
}

sub _ext_isgid {
	return Puzzle->instance->session->user->isGid(shift);
}


sub _ext_s {
	return Puzzle->instance->lang->s(shift);
}

sub _split_date {
	my $mysql_date	= shift;
	my @dcomp				= split('-',$mysql_date);
	if ($#dcomp == 2) {
		my @tcomp = split(' ',$dcomp[2]);
		if ($#tcomp == 1) {
			# have time
			$dcomp[2] = $tcomp[0];
			@tcomp = split(':',$tcomp[1]);
			@ret =  (@dcomp,@tcomp);
		} else {
			@ret =  (@dcomp,'00','00','00');
		}
	} else {
		# not a date
		return ($mysql_date);
	}
	@ret = map(length($_) == 1 ? "0$_" :  $_,@ret);
	return @ret;
}

sub combo_selected {
	my $s			= shift;
	my $arraylist	= shift;
	my $keyname		= shift;
	my $vselected	= shift;

	LOOP: foreach (@$arraylist) {
		if ($_->{$keyname} eq $vselected) {
			$_->{selected} = 'selected';
			last LOOP;
		}
	}
}

1;

# vim: set ts=2:
