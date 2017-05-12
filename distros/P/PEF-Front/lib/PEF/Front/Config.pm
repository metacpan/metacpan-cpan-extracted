package PEF::Front::Config;
use warnings;
use strict;
use FindBin;
use File::Basename;
use feature 'state';
our $project_dir;
our $app_conf_dir;
our $app_namespace;

sub normalize_path {
	my $path = $_[0];
	if (not $path) {
		return '.';
	} elsif (substr($path, -1, 1) ne '/') {
		return $path;
	} else {
		return substr($path, 0, -1);
	}
}

my @std_const_params = qw{
	cfg_upload_dir
	cfg_captcha_db
	cfg_captcha_font
	cfg_captcha_image_init
	cfg_captcha_image_class
	cfg_captcha_secret
	cfg_captcha_symbols
	cfg_captcha_expire_sec
	cfg_model_dir
	cfg_cache_file
	cfg_cache_size
	cfg_cache_method_expire
	cfg_cookie_unset_negative_expire
	cfg_www_static_dir
	cfg_www_static_captchas_dir
	cfg_www_static_captchas_path
	cfg_in_filter_dir
	cfg_out_filter_dir
	cfg_db_user
	cfg_db_password
	cfg_db_name
	cfg_db_reconnect_trys
	cfg_model_local_dir
	cfg_project_dir
	cfg_app_namespace
	cfg_default_lang
	cfg_url_contains_lang
	cfg_url_only_camel_case
	cfg_template_dir_contains_lang
	cfg_no_multilang_support
	cfg_location_error
	cfg_template_cache
	cfg_no_nls
	cfg_handle_static
	cfg_log_level_info
	cfg_log_level_error
	cfg_log_level_debug
	cfg_session_db_file
	cfg_session_ttl
	cfg_session_request_field
	cfg_oauth_connect_timeout
	cfg_unknown_msgid_db
	cfg_collect_unknown_msgid
	cfg_model_rules_reload
};

my @std_var_params = qw{
	cfg_context_post_hook
	cfg_template_dir
	cfg_model_rpc
	cfg_oauth_client_id
	cfg_oauth_client_secret
	cfg_oauth_scopes
	cfg_logger
	cfg_parse_extra_params
};

our %config_export;

sub import {
	my ($modname) = grep {/AppFrontConfig\.pm$/} keys %INC;
	die "no config" if 0 && !$modname;
	$modname = 'fakemodule::' if !$modname;
	(undef, $app_conf_dir, undef) = fileparse($INC{$modname} || '', ".pm");
	$app_conf_dir = normalize_path($app_conf_dir);
	$modname =~ s|\.pm||;
	$modname =~ s|/|::|g;
	($app_namespace = $modname) =~ s/::[^:]*$/::/;
	my $mp = __PACKAGE__;
	my $cp = caller;
	no strict 'refs';
	my @pa = (\@std_const_params, \@std_var_params);

	for (my $i = 0; $i < @pa; ++$i) {
		for my $method (@{$pa[$i]}) {
			(my $bmn = $method) =~ s/^cfg_//;
			my $cref = "$modname"->can($method) || *{$mp . "::std_$bmn"};
			*{$mp . "::$method"}      = $cref;
			*{$cp . "::$method"}      = *{$mp . "::$method"};
			*{$modname . "::$method"} = $cref if not "$modname"->can($method);
			$config_export{$method} = $cref if $i == 0;
		}
	}
	my $exports = \@{$modname . "::EXPORT"};
	for my $e (@$exports) {
		if ((my $cref = "$modname"->can($e))) {
			*{$cp . "::$e"} = $cref;
			$config_export{$e} = $cref;
		}
	}
	if ("$modname"->can("project_dir")) {
		$project_dir = normalize_path("$modname"->project_dir);
	} else {
		my $lpath = $FindBin::Bin;
		$lpath =~ s'(/app$|/conf$|/bin$)'';
		$project_dir = $lpath;
	}
}

sub std_project_dir                  {$project_dir}
sub std_no_nls                       {0}
sub std_unknown_msgid_db             {cfg_project_dir() . "/var/cache/unknown-msgid.db"}
sub std_collect_unknown_msgid        {0}
sub std_template_cache               {cfg_project_dir() . "/var/tt_cache"}
sub std_location_error               {"/appError?msgid=Internal\%20Error"}
sub std_db_reconnect_trys            {30}
sub std_no_multilang_support         {1}
sub std_default_lang                 {'en'}
sub std_url_contains_lang            {0}
sub std_url_only_camel_case          {1}
sub std_template_dir_contains_lang   {0}
sub std_handle_static                {0}
sub std_app_namespace                {$app_namespace}
sub std_in_filter_dir                {"$app_conf_dir/InFilter"}
sub std_model_local_dir              {"$app_conf_dir/Local"}
sub std_out_filter_dir               {"$app_conf_dir/OutFilter"}
sub std_upload_dir                   {cfg_project_dir() . "/var/upload"}
sub std_captcha_db                   {cfg_project_dir() . "/var/captcha-db"}
sub std_captcha_font                 {"giant"}
sub std_captcha_image_init           {{}}
sub std_captcha_image_class          {"PEF::Front::SecureCaptcha"}
sub std_captcha_secret               {$app_namespace}
sub std_captcha_expire_sec           {300}
sub std_cache_file                   {cfg_project_dir() . "/var/cache/shared.cache"}
sub std_cache_size                   {"8m"}
sub std_cache_method_expire          {60}
sub std_model_rules_reload           {0}
sub std_model_dir                    {cfg_project_dir() . "/model"}
sub std_www_static_dir               {cfg_project_dir() . "/www-static"}
sub std_www_static_captchas_dir      {cfg_project_dir() . "/www-static/captchas"}
sub std_db_user                      {"pef"}
sub std_db_password                  {"pef-pass"}
sub std_db_name                      {"pef"}
sub std_log_level_info               {1}
sub std_log_level_error              {1}
sub std_log_level_debug              {0}
sub std_session_db_file              {cfg_project_dir() . "/var/cache/session.db"}
sub std_session_ttl                  {86400 * 30}
sub std_session_request_field        {'auth'}
sub std_cookie_unset_negative_expire {-3600}
sub std_oauth_connect_timeout        {15}

sub std_captcha_symbols {
	state $symbols = ["0" .. "9", split //, "abCdEFgHiJKLMNOPqRSTUVWXyZ"];
	$symbols;
}

sub std_www_static_captchas_path {
	if (substr(cfg_www_static_captchas_dir(), 0, length(cfg_www_static_dir())) eq cfg_www_static_dir()) {
		# removes cfg_www_static_dir() from cfg_www_static_captchas_dir() and adds '/'
		substr(cfg_www_static_captchas_dir(), length(cfg_www_static_dir())) . '/';
	} else {
		#must be overriden by user
		'/captchas/';
	}
}

sub std_context_post_hook { }

sub std_template_dir {
	cfg_template_dir_contains_lang()
		? cfg_project_dir() . "/templates/$_[1]"
		: cfg_project_dir() . "/templates";
}

sub std_model_rpc {
	PEF::Front::Model::chain_links($_[0]);
}

sub std_oauth_client_id {
	state $ids = {
		yandex     => 'anonymous',
		google     => 'anonymous',
		facebook   => 'anonymous',
		v_kontakte => 'anonymous',
		git_hub    => 'anonymous',
	};
	$ids->{$_[0]};
}

sub std_oauth_client_secret {
	state $secrets = {
		yandex     => 'anonymous_secret',
		google     => 'anonymous_secret',
		facebook   => 'anonymous_secret',
		v_kontakte => 'anonymous_secret',
		git_hub    => 'anonymous_secret',
	};
	$secrets->{$_[0]};
}

sub std_oauth_scopes {
	state $scopes = {
		yandex     => {user_info => undef},
		v_kontakte => {user_info => undef},
		git_hub    => {user_info => 'user'},
		google     => {
			email     => 'https://www.googleapis.com/auth/userinfo.email',
			share     => 'https://www.googleapis.com/auth/plus.stream.write',
			user_info => 'https://www.googleapis.com/auth/userinfo.email https://www.googleapis.com/auth/userinfo.profile'
		},
		facebook => {
			email     => 'email',
			share     => 'publish_actions',
			user_info => 'email',
			offline   => 'offline_access'
		},
		v_kontakte => {user_info => undef},
		git_hub    => {user_info => 'user'},
		msn        => {
			email     => 'wl.emails',
			offline   => 'wl.offline_access',
			share     => 'wl.share',
			user_info => 'wl.basic wl.emails',
		},
		paypal => {
			email     => 'email',
			user_info => 'email profile phone address',
			all       => 'email openid profile phone address'
				. 'https://uri.paypal.com/services/paypalattributes'
				. ' https://uri.paypal.com/services/expresscheckout',
		},
		linked_in => {
			email     => 'r_emailaddress',
			share     => 'rw_nus',
			user_info => 'r_emailaddress r_fullprofile',
			}

	};
	$scopes->{$_[0]};
}

sub std_logger {
	my $request = $_[0];
	$request->{env}{'psgix.logger'}
		|| sub {$request->{env}{'psgi.errors'}->print($_[0]->{message});}
}

sub std_parse_extra_params {
	my ($src, $params, $form) = @_;

	if (($src eq 'get' || $src eq 'app') && $params ne '') {
		my @params = split /\//, $params;
		my $i = 1;
		for my $pv (@params) {
			my ($p, $v) = split /-/, $pv, 2;
			if (!defined($v)) {
				$v = $p;
				$p = 'cookie';
				if (exists $form->{$p}) {
					$p = "get_param_$i";
					++$i;
				}
			}
			$form->{$p} = $v;
		}
	}
}

sub cfg {
	my $key     = $_[0];
	my $cfg_key = "cfg_" . $key;
	if (exists $config_export{$cfg_key}) {
		$config_export{$cfg_key}->();
	} elsif (exists $config_export{$key}) {
		$config_export{$key}->();
	} else {
		warn "Unknown config key: $key";
		undef;
	}
}

1;

__END__

=head1 NAME

B<PEF::Front::Config> - how to configure PEF::Front to suit your needs

=head1 DESCRIPTION

B<PEF::Front::Config> handles configuration of your apps. 
The documentation for this module aims to describe how to change
settings, and which settings are available.

=head1 SETTINGS
 
Subroutine names in your configuration module B<*::AppFrontConfig> define
configuration parameters. This module has to be loaded first on startup.
B<PEF::Front> has many sensible defaults but you have to provide some data.  
 
  package MyApp::AppFrontConfig;
  sub cfg_db_user      { "user" }
  sub cfg_db_password  { "mypassword" }
  sub cfg_db_name      { "mydb" }
  1; 

In these subroutines you can return some constants or load them from some 
source. 

You can define your own subroutines and export them to your handlers.
B<PEF::Front::Config> has some limited functionality of L<Exporter>. 

  package MyApp::AppFrontConfig;
  our @EXPORT = qw(avatar_images_path);
  sub avatar_images_path { cfg_www_static_dir() .'/images/avatars' }

  # somewhere in handlers
  package MyApp::Local::Avatar;
  use PEF::Front::Config;

  sub upload {
    my ($req, $ctx) = @_;
    my $upload_path = avatar_images_path();
    # ...
  }

It works a little-bit non-trivial: B<PEF::Front> reads parameters from 
MyApp::AppFrontConfig, determines the whole configuration and re-export
it into MyApp::AppFrontConfig. This way you can use automatically calculated
configuration data in your configuration subroutines. 

B<< PEF::Front::Config::cfg( C<$config_key>) >> returns configuration 
value for the given C<$config_key> if it doesn't require parameter.

=head1 SUPPORTED SETTINGS
 
=over

 
=item B<cfg_app_namespace>

Application modules namespace. By default it's calculated from full 
name of your B<*::AppFrontConfig> module. But probably you can change it for
some unknown reason.

=item B<cfg_cache_file>

Full path to cache file. 
Default is C<cfg_project_dir() . "/var/cache/shared.cache">

=item B<cfg_cache_method_expire>

Default expire time for cached responses. 
By default it's equal to 60 [seconds].

=item B<cfg_cache_size>

Cache size. Default is equal to "8m" = 8 Megabytes.

=item B<cfg_captcha_db>

Sets the directory to hold the database that will be used to store the current
non-expired valid captcha tokens. 
Default is C<cfg_project_dir() . "/var/captcha-db">

=item B<cfg_captcha_expire_sec>

Sets the number of seconds this captcha will remain valid. Default is 300.

=item B<cfg_captcha_font>

The absolute path to your TrueType (.ttf) font file. 
Be aware that relative font paths are not recognized due to problems in the 
libgd library. Default is "giant" - not a good font, you would better 
change it.

=item B<cfg_captcha_image_class>

Allows to inject user's captcha image generation class. 
Default is "PEF::Front::SecureCaptcha" which is really not very
pretty but works. Captcha image generation class have to implement only
one method: 

  generate_image(
    width      => $width,
    height     => $height,
    size       => $size,
    str        => $str,
    code       => $sha1,
    out_folder => $cfg_www_static_captchas_dir,
    font       => cfg_captcha_font(),
    %$image_init,
  )

Where $image_init is optional hash reference 
from B<cfg_captcha_image_init> parameter.

=item B<cfg_captcha_image_init>

Optional hash reference of extra values 
for captcha's generate_image method.

=item B<cfg_captcha_secret>

Salt for secure captcha's code generation. Default is B<cfg_app_namespace>.

=item B<cfg_captcha_symbols>

Array of symbols for captcha's code.

=item B<cfg_collect_unknown_msgid>

Boolean value whether to collect or not not translated localized phrases. 
You can translate these collected phrases later.

=item B<cfg_cookie_unset_negative_expire>

Cookie-unset sets expiration time of the cookie in the past. This parameter 
says how much in the past. Default is -3600 seconds - 1 hour.  

=item B<cfg_db_name>

Default full DSN or PostgreSQL's database name. 
Default is "pef" which is pretty useless. 
Here "pef" really means "dbi:Pg:dbname=pef".

=item B<cfg_db_password>

Default password for DB user.

=item B<cfg_db_reconnect_trys>

How many times it tries to reconnect with 1 second pauses
in case some DB connection failure. During this time all
queries will be waiting for connection. They will fail after
final failure or continue to work as if nothing happened if 
connection finally comes back.

=item B<cfg_db_user>

Default DB user name.

=item B<cfg_default_lang>

Default localization language when guessing from HTTP headers or Geo IP 
doesn't help. 

=item B<cfg_handle_static>

Boolean value whether your application handle static content or not. 
Default is false - it is better served by some fast server like 
L<Nginx|https://www.nginx.com/>.

=item B<cfg_in_filter_dir>

Directory of input parameter filter modules. It's better not to change, 
use it as read-only value. Changing this value you can break framework.
Default is "$app_project_dir/InFilter". 

=item B<cfg_location_error>

Redirect for location errors (404). 
Default is "/appError?msgid=Internal\%20Error".

=item B<cfg_log_level_debug>

Boolean value whether debug logging is on. Default is false.

=item B<cfg_log_level_error>

Boolean value whether error logging is on. Default is true.

=item B<cfg_log_level_info>

Boolean value whether informational logging is on. Default is true.

=item B<cfg_model_dir>

Directory of model description YAML-files. 
Default is cfg_project_dir() . "/model".

=item B<cfg_model_local_dir>

Directory of "local" model handlers modules. Do not change it.
Default is "$app_project_dir/Local". 

=item B<cfg_model_rules_reload>

When true, checks wheater file was modified on every input data validation
and reloads model description if necessary.
Default is false. 

=item B<cfg_no_multilang_support>

Boolean value whether application supports multilanguage. Default is true.

=item B<cfg_no_nls>

Boolean value whether application localization is off. Default is false.
Localization can work without multilanguage support.

=item B<cfg_oauth_connect_timeout>

Timeout for operations with Oauth2-providers. Default is 15 seconds. 

=item B<cfg_out_filter_dir>

Directory of response output filter modules. It's better not to change, 
use it as read-only value. Changing this value you can break framework.
Default is "$app_project_dir/OutFilter". 

=item B<cfg_project_dir>

Root directory of your application. It is guessed by default from 
path to your startup file.

=item B<cfg_session_db_file>

Sets database file that will be used to store the user session data.
Default is cfg_project_dir() . "/var/cache/session.db".

=item B<cfg_session_request_field>

Sets session identifier field from cookies or form data. Session data
can be automatically loaded during request validation. Default is "auth".

=item B<cfg_session_ttl>

Time to live for session data. Default is 30 days.

=item B<cfg_template_cache>

Sets directory for compiled templates.
Default is cfg_project_dir() . "/var/tt_cache".

=item B<cfg_template_dir_contains_lang>

Boolean value whether templates for different languages are in their own 
directories.  Default is false. 

=item B<cfg_unknown_msgid_db>

Sets database file for not translated localized messages. 
You can export these phrases into POT file and translate them later. 
Default is cfg_project_dir() . "/var/cache/unknown-msgid.db". 

=item B<cfg_upload_dir>

Root directory for uploaded files.
Default is cfg_project_dir() . "/var/upload".

=item B<cfg_url_contains_lang>

Boolean value whether URI path is prefixed with short language name
like /en/, /de/, etc. Default is false.

=item B<cfg_url_only_camel_case>

Boolean value whether routed path can be only in Camel Case form. 
Default is true.

=item B<cfg_www_static_captchas_dir>

Directory for generated captcha images. 
Default is cfg_project_dir() . "/www-static/captchas".

=item B<cfg_www_static_captchas_path>

URI path for generated captcha images.
Default is deducted cfg_www_static_dir from cfg_www_static_captchas_dir.

=item B<cfg_www_static_dir>

Directory of static content that is usually served directly by web-server.

=back

=head1 PARAMETRIZED HOOKS

=over

=item B<cfg_context_post_hook($context)>

This function is called when request context is already made up but 
handler is not called yet.

=item B<cfg_logger($request)>

This method should return subroutine that 
accept ({level => "warn", message => $message}) and writes log message.
By default this function returns 

  $request->{env}{'psgix.logger'} 
  || sub {$request->{env}{'psgi.errors'}->print($_[0]->{message});} 

=item B<cfg_model_rpc($method)>

This function return subroutine reference that calls "remote" methods
for given C<$model>. That referenced subroutine recieves 
C<($validated_request, $context)> parameters.

=item B<cfg_oauth_client_id($service)>

Returns C<client id> of your application for given $service. 
Default is 'anonymous'.

=item B<cfg_oauth_client_secret($service)>

Returns C<client secret> of your application for given $service. 
Default is 'anonymous_secret'.

=item B<cfg_oauth_scopes($service)>

Returns scopes for given $service. Default is quite sensible 
for all supported services to obtain user info.

=item B<cfg_parse_extra_params($src, $params, $form)>

Parses extra parameters from request's path.

By default if C<$src> is on of 'app', 'get' then it splits path by '/'
and tries to split every part into pair divided by '-'. Left part is
parameter name and right part is value. If it was not possible to split
by '-' then first parameter is named C<cookie> and rest is C<get_param_$i>
with increasing from 1 C<$i>.

=item B<cfg_template_dir($request, $lang)>

Returns one or more directories with templates.
Default is cfg_project_dir() . "/templates" or 
cfg_project_dir() . "/templates/$lang" depending on 
cfg_template_dir_contains_lang. 


=back

=head1 AUTHOR
 
This module was written and is maintained by Anton Petrusevich.

=head1 Copyright and License
 
Copyright (c) 2016 Anton Petrusevich. Some Rights Reserved.
 
This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
