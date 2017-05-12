package Puzzle::MasonHandler;

our $VERSION = '0.21';

use HTML::Mason::ApacheHandler();

use strict;

{
	package Puzzle::Request;
	use Apache2::Request;
	use Apache2::Cookie;
	use Apache::DBI;
	use Apache::Session::MySQL;
	use I18N::AcceptLanguage;
	use HTML::Template::Pro::Extension;
}

my %perl2apache 	= (
						args_method			=> 'MasonArgsMethod',
						comp_root			=> 'MasonCompRoot',
						data_dir			=> 'MasonDataDir',
						code_cache_max_size	=> 'MasonCodeCacheMaxSize',
						autoflush 			=> 'MasonAutoflush',
						dhandler_name 		=> 'MasonDhandlerName',
						request_class		=> 'MasonRequestClass',
						error_mode			=> 'MasonErrorMode',
						static_source		=> 'MasonStaticSource',
);

my %ah;

sub params 		{return 	( 
						args_method			=> 'mod_perl',
						comp_root			=> "/www/$_[0]/www",
						data_dir			=> "/var/cache/mason/cache/$_[0]",
						code_cache_max_size	=> 0,
						autoflush 			=> 0,
						dhandler_name 		=> 'dhandler.mpl',
						request_class		=> 'Puzzle::Request',
						error_mode			=> 'output',
						static_source		=> 0,
)};

sub handler {
	my ($r)	= @_;
	my $sn    = $r->dir_config('ServerName');
	my %params = &params($sn);
	foreach my $key (keys %params) {
		if (exists $perl2apache{$key}) {
			$params{$key} = $r->dir_config($perl2apache{$key}) 
				if ($r->dir_config($perl2apache{$key}));
		}
	}
	$ah{$sn} = new HTML::Mason::ApacheHandler(%params) unless (exists $ah{$sn});
	return $ah{$sn}->handle_request($r);
}

1;

# vim: set ts=2:
