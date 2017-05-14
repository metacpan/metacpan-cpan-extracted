package MyLibrary::Config;

	our $DATA_SOURCE = 'DBI:mysql:mylibrary';
	our $USERNAME = 'nobody';
	our $PASSWORD = 'nobody';
	our $ML_KEY = '';
	our $SESSION_DIR = '';
	our $RELATIVE_PATH = '';
	our $COOKIE_DOMAIN = '';
	our $HOME_URL = '';
	our $SCRIPTS_URL = '';
	our $SECURE_SCRIPTS_URL = '';
	our $NAME_OF_APPLICATION = '';
	our $JAVASCRIPT_URL = '';
	our $CSS_URL = '';
	our $SSI_URL = '';
	our $IMAGE_URL = '';
	our %SSI_PAGES = ();
	our $INDEX_DIR = '';

	my %instances = ();


sub instance {

	my $class = shift;
	my $instance = shift;

	if ($instance && $instance ne 'default') {
		my %instance_params = %{$instances{$instance}};
		our $DATA_SOURCE = $instance_params{'DATA_SOURCE'};
		our $USERNAME = $instance_params{'USERNAME'};
		our $PASSWORD = $instance_params{'PASSWORD'};
		our $ML_KEY = $instance_params{'ML_KEY'};
		our $SESSION_DIR = $instance_params{'SESSION_DIR'};
		our $RELATIVE_PATH = $instance_params{'RELATIVE_PATH'};
		our $COOKIE_DOMAIN = $instance_params{'COOKIE_DOMAIN'};
		our $HOME_URL = $instance_params{'HOME_URL'};
		our $SCRIPTS_URL = $instance_params{'SCRIPTS_URL'};
		our $SECURE_SCRIPTS_URL = $instance_params{'SECURE_SCRIPTS_URL'};
		our $NAME_OF_APPLICATION = $instance_params{'NAME_OF_APPLICATION'};
		our $JAVASCRIPT_URL = $instance_params{'JAVASCRIPT_URL'};
		our $CSS_URL = $instance_params{'CSS_URL'};
		our $SSI_URL = $instance_params{'SSI_URL'};
		our $IMAGE_URL = $instance_params{'IMAGE_URL'};
		our %SSI_PAGES = @{$instance_params{'SSI_PAGES'}};
		our $INDEX_DIR = $instance_params{'INDEX_DIR'};
	}

}

1;
