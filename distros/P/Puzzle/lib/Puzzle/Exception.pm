package Puzzle::Exception;

our $VERSION = '0.21';

use base 'Class::Container';
use File::Spec;

sub raise {
	my $self		= shift;
	my $error_code	= shift;

	my $tmpl		= $self->container->tmpl;
	my $mason		= $self->container->_mason;

	# add original component yaml structures to add errors
	my $comp_path	= $mason->current_comp->source_file;

	my @dots = split(/\./,$comp_path);
	$dots[-1] = 'yaml';
	my $yaml_path = join('.',@dots);
	if (-e $yaml_path) {
		my $lang = $self->container->lang_manager->lang;
		my $yaml_args = $tmpl->yamlArgs($yaml_path,$lang);
		foreach (qw/cod descr linkback/) {
			if (exists $yaml_args->{exception}->{$error_code}->{$_}) {
				$self->container->args->set('exception.'. $_ =>
				$yaml_args->{exception}->{$error_code}->{$_});
			}
		}
	}


	$self->container->args->set(errorcode => $error_code);
	$self->print;
	# usefull to return your function with 0 if errors
	return 0;
}

sub print {
	my $self	= shift;
	my $error_path = $self->container->cfg->exception_file;
	print $self->container->tmpl->html(undef,$error_path);

}

1;
