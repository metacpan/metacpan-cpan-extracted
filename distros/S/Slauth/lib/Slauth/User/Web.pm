# Slauth web interface

package Slauth::User::Web;

use strict;
#use warnings FATAL => 'all', NONFATAL => 'redefine';
use Slauth::Config;
use Slauth::Config::Apache;
BEGIN {
	if ( $Slauth::Config::Apache::MOD_PERL >= 2 ) {
		require Apache2::Response;
		require Apache2::RequestRec;
		require Apache2::RequestUtil;
		require Apache2::RequestIO;
		require Apache2::URI;
		require Apache2::Const;
		import Apache2::Const qw( HTTP_OK OK REDIRECT );
	} else {
		require Apache2;
		require Apache::RequestRec;
		require Apache::RequestIO;
		require Apache::RequestUtil;
		require Apache::Const;
		import Apache::Const qw( HTTP_OK OK REDIRECT );
	}
	require APR::Pool;
	require APR::Table;
}
use Slauth::Storage::Session_DB;
use Slauth::Storage::User_DB;
use CGI qw( :common );
use CGI::Carp qw(fatalsToBrowser);

sub debug { $Slauth::Config::debug; }

sub new
{
        my $class = shift;
        my $self = {};
        bless $self, $class;
        $self->initialize(@_);
        return $self;
}

sub initialize
{
	my $self = shift;

	# check for valid parameters
	while ( @_ ) {
		my $pname = shift;
		my $pval = shift;
		if ( $pname eq "request" ) {
			$self->{r} = $pval;
		}
	}
	
	# set up CGI.pm
	my $cgi = CGI->new();
	$self->{cgi} = $cgi;

	# instantiate the configuration
	$self->{config} = Slauth::Config->new(
		( defined $self->{r}) ? $self->{r} : ());

	# set up tags for template
	my $server_name = $cgi->server_name;
	$self->{tags} = {
		"self_url" => $self->self_url,
		"script_name" => $cgi->script_name,
		"path_info" => $cgi->path_info,
		"referer" => $cgi->referer,
		"remote_addr" => $cgi->remote_addr,
		"remote_host" => $cgi->remote_host,
		"remote_user" => $cgi->remote_user,
		"request_method" => $cgi->request_method,
		"server_name" => $cgi->server_name,
		"server_port" => $cgi->server_port,
		"user_agent" => $cgi->user_agent,
		"server_port" => $cgi->server_port,
		"server_protocol" => $cgi->server_protocol,
	};

	# open the template file
	my $slauth_dir = $self->get( "dir" );
	my $template_file = $self->get( "template" );
	if ( ! open ( TFILE, "$slauth_dir/$template_file" )) {
		close TFILE;
		croak "can't open slauth template file: $!\n";
	}

	# gulp the template
	$self->{template} = [];
	@{$self->{template}} = <TFILE>;
	close TFILE;

	# get request path
	if ( $cgi->path_info eq "" ) {
		return $self->redirect( $cgi->self_url."/" );
	}
	$self->{path} = [];
	@{$self->{path}} = split ( '/', $cgi->path_info );
	shift @{$self->{path}};

	# attempt to get the remote IP address if we're running mod_perl 2.0
	#eval {
	#	use Apache::RequestUtil;
	#	my $r = Apache->request;
	#	my $c = $r->connection;
	#	$self->{remote_addr} = $c->remote_addr->ip_get;
	#} or $self->{remote_addr} = $cgi->remote_addr;
	$self->{remote_addr} = $cgi->remote_addr;
}

# get configuration value
# configuration values are read-only
sub get
{
	my ( $self, $key ) = @_;
	return $self->{config}->get( $key );
}

# read CGI parameters
# CGI paramaters are read-only
sub param
{
	my ( $self, $name ) = @_;

	if ( defined $name ) {
		return $self->{cgi}->param($name);
	} else {
		return $self->{cgi}->param;
	}
}

# set cookies for response
sub cookie
{
	my $self = shift;
	if ( ! defined $self->{cookies}) {
		$self->{cookies} = [];
	}
	my $cookie = $self->{cgi}->cookie( @_ );
	push ( @{$self->{cookies}}, $cookie );
}

# get or set template tag value
# template tags are read-write
sub tag
{
	my ( $self, $name, $value ) = @_;

	if ( defined $value ) {
		if ( defined $self->{tags}{$name}) {
			$self->{tags}{$name} .= "\n".$value;
		} else {
			$self->{tags}{$name} = $value;
		}
	} else {
		if ( defined $self->{tags}{$name}) {
			return $self->{tags}{$name}
		}
		return undef;
	}
}

# main web interface function
sub interface
{
	my $self = shift;
	my $cgi = $self->{cgi};
	my $realm = $self->get( "realm" );

	# determine content from request path
	my @path;
	if ( defined $self->{path}) {
		@path = @{$self->{path}};
	}
	debug and print STDERR "Slauth::User::Web::interface: realm=$realm "
		."path=".join(' / ', @path)."\n";
	if ( ! @path ) {
		$self->{tags}{subtitle} = "Authentication Menu",
		$self->{tags}{text} = "<ul>\n"
			."<li><a href=\"".$cgi->script_name."/login/\">Log in</a>\n"
			."<li><a href=\"".$cgi->script_name."/register/\">Register for new authenticated access</a>\n"
			."<li><a href=\"".$cgi->script_name."/maint/\">Maintain your existing authenticated access</a>\n"
			."</ul>\n",
	} elsif ( $path[0] eq "register" ) {
		$self->do_register;
	} elsif ( $path[0] eq "login" ) {
		$self->do_login;
	} elsif ( $path[0] eq "error-login" ) {
		$self->do_login;
	} elsif ( $path[0] eq "maint" ) {
		$self->do_maint;
	} else {
		$self->{tags}{subtitle} = "Unrecognized Path",
		$self->{tags}{text} = "The path you requested does not exist.",
	}

	# handle redirects
	if ( defined $self->{tags}{dest}) {
		return $self->redirect( $self->{tags}{dest} );
	}

	#
	# send HTTP response
	#

	# start with response headers
	my @header_params;

	# set content type
	if ( defined $self->{r}) {
		$self->{r}->content_type( "text/html" );
		$self->{r}->no_cache(1);
	} else {
		push ( @header_params, -type => "text/html" );
	}

	# set cookies
	if ( defined $self->{cookies}) {
		my $cookie;
		foreach $cookie ( @{$self->{cookies}}) {
			debug and print STDERR "Slauth::User::Web::interface: "
				."cookie=$cookie\n";
			if ( defined $self->{r}) {
				# mod_perl mode
				$self->{r}->headers_out->add(
					'Set-Cookie' => $cookie );
			} else {
				# CGI mode
				push ( @header_params, -cookie => $cookie );
			}
		}
	}

	# set response status
	if ( !defined $self->{tags}{status}) {
		if ( defined $self->{r}) {
			$self->{tags}{status} = HTTP_OK;
		} else {
			$self->{tags}{status} = 200;
		}
	}
	debug and print STDERR "Slauth::User::Web::interface: "
		."status=".$self->{tags}{status}."\n";
	if ( defined $self->{r}) {
		# mod_perl mode
		$self->{r}->status($self->{tags}{status});
	} else {
		# CGI mode
		push ( @header_params, -status => $self->{tags}{status});
	}

	# send headers out
	if ( defined $self->{r}) {
		$self->{r}->rflush;
		$self->{r}->print( "\n" );
	} else {
		if ( @header_params ) {
			print $cgi->header(@header_params);
		} else {
			print $cgi->header;
		}
	}

	# print text response
	$self->template_out;
	if ( defined $self->{r}) {
		return OK;
	} else {
		return;
	}
}

sub template_out {
	my $self = shift;
	my $template = $self->{template};
	my $i;

	for ( $i = 0; $i < @$template; $i++ ) {
		print $self->template_line( $template->[$i]);
	}
}

sub template_line
{
	my ( $self, $line ) = @_;
	my $tags = $self->{tags};
	my ( $result );

	( defined $line ) or return;
        if ( $line =~ /^(.*)\%([a-z0-9_]+)\%(.*)/s ) {
                my ( $before, $tag, $after ) = ( $1, $2, $3 );
                if ( defined $tags->{$tag}) {
			if ( ref $tags->{$tag} eq "CODE" ) {
				$result = $tags->{$tag}($tags);
			} elsif ( ref $tags->{$tag} eq "ARRAY" ) {
				$result = "\n".join( "", (@{$tags->{$tag}}))
					."\n";
			} else {
				$result = $tags->{$tag};
			}
                } else {
                        $result = $self->get( $tag );
			if ( !defined $result ) {
				$result = "";
			}
                }
                return $self->template_line($before)
			.$self->template_line($result)
			.$self->template_line($after);
        } else {
                return $line;
        }

}

sub check_params
{
	my $self = shift;
	my ( @reqs ) = @_;

	foreach ( @reqs ) {
		defined $self->param( $_ ) or return 0;
	}
	return 1;
}

sub new_session
{
	my $self = shift;
	my $login = shift;
	my $text;

	# create login session
	my $session_db = Slauth::Storage::Session_DB->new($self->{config});
	if ( $session_db->error ) {
		$text = "An error has occurred.\n";
		$text .= "The storage subsystem failed.\n";
		$text .= "Your user record was stored\n";
		$text .= "with the password you used.\n";
		$text .= "A login session was not started.\n";
		goto DONE;
	}

	my $session_hash = $session_db->write_record( $login, $self->{config});

	# set the cookie
	if ( $session_hash ) {
		my $domain = $self->get( "cookie-domain" );
		my $expires = $self->get( "cookie-expires" );
		my @cookie_params = (
			-name => "slauth_session",
			-value => $session_hash );
		if ( defined $domain ) {
			push ( @cookie_params, 
				-domain => $domain );
		}
		if ( defined $expires ) {
			push ( @cookie_params, 
				-expires => $expires );
		}
		$self->cookie( @cookie_params );
		if ( $self->param("dest")) {
			# transfer destination URL to
			# result tags
			$self->tag( "dest", 
				$self->param("dest"));
			return; # skip text tag processing
		}
		$text = "Login successful.\n";
		$text .= "A cookie has been set in your\n";
		$text .= "browser which will allow you\n";
		$text .= "into restricted areas of the\n";
		$text .= "site appropriate to your\n";
		$text .= "mail list memberships.\n";
	} else {
		$text = "An error has occurred.\n";
		$text .= "The storage subsystem failed.\n";
		$text .= "Your user record was stored\n";
		$text .= "with the password you used.\n";
		$text .= "A login session was not started.\n";
	}

	DONE:
	$self->tag("text", $text );
}

sub do_register
{
	my $self = shift;
	my $cgi = $self->{cgi};
	my $tags = $self->{tags};
	my %register;
	foreach my $class ( split ( /\s+/, $self->get( "register" ))) {
		my $reg;
		eval "require $class" or croak "failed to load $class: $!\n";
		$reg = $class->new($self->{config});
		if ( my $short_name = $reg->short_name ) {
			$register{$short_name} = $reg;
		}
	}

	if ( defined $self->{path}[1]) {
		my $reg = $register{$self->{path}[1]};
		if ( defined $reg and ref $reg ne "" ) {
			if ( defined $self->{path}[2]) {
				my @subpath = @{$self->{path}};
				shift @subpath;
				shift @subpath;
				$reg->process_path($self, @subpath );
			} elsif ( $self->check_params( $reg->req_params )) {
				my %vars = $cgi->Vars;
				$reg->process_form( $self );
			} else {
				$tags->{subtitle} = $reg->long_name;
				$tags->{text} = $reg->html_form( $self );
			}
		} else {
			croak "bad registration method '"
				.$self->{path}[1]."'\n";
		}
	} else {
		my @keys = keys %register;
		if ( @keys == 1 ) {
			# If there's only one registration method,
			# don't bother with a menu. Just redirect to it.
			$self->{tags}{dest} = $self->{cgi}->script_name
				."/".$self->{path}[0] ."/".$keys[0];
			return;
		}
		$tags->{subtitle} = "Web Access Registration",
		$tags->{text} = "Please select a registration method.\n";
		$tags->{text} .= "<ul>\n";
		foreach my $key ( keys %register ) {
			$tags->{text} .= "<li><a href=\""
				.$self->{cgi}->script_name
				."/".$self->{path}[0] ."/".$key."\">"
				.($register{$key}->long_name )
				."</a>\n";
		}
		$tags->{text} .= "</ul>\n";
	}
}

sub do_login
{
	my $self = shift;
	my $cgi = $self->{cgi};
	my $tags = $self->{tags};
	my ( $text, $dest );

	if ( $self->{path}[0] eq "error-login" ) {
		$dest = $tags->{self_url};
	}

	# if login and pw are provided, process the login attempt
	if ( $self->check_params( "login", "pw" )) {
		my $login = $cgi->param("login");
		my $pw = $cgi->param("pw");
		debug and print STDERR "Slauth::User::Web::interface: "
			."check login=$login\n";
		if ( Slauth::Storage::User_DB::check_pw( $login, $pw,
			$self->{config}))
		{
			$self->new_session( $login );
			return;
		} else {
			$text = "The login information was incorrect.\n";
		}

	# otherwise provide a login form
	} else {
		debug and print STDERR "Slauth::User::Web::interface: "
			."login form\n";
		$text = "<form method=POST action=\"".$cgi->script_name()
			."/login/\">\n";
		if ( defined $dest ) {
			$text .= "<input type=hidden name=dest "
				."value=\"".CGI::escapeHTML($dest)."\">\n";
		}
		$text .= "<center><table border=1>\n";
		$text .= "<tr>\n";
		$text .= "<td colspan=2 align=center>\n";
		$text .= "<b>Please log in</b>\n";
		$text .= "<br>\n";
		$text .= "<small><i>You must enable cookies in your browser\n";
		$text .= "to continue</i></small>\n";
		$text .= "</td>\n";
		$text .= "</tr><tr>\n";
		$text .= "<td>User name:</td>\n";
		$text .= "<td><input type=text name=login size=15></td>\n";
		$text .= "</tr><tr>\n";
		$text .= "<td>Password:</td>\n";
		$text .= "<td><input type=password name=pw size=15></td>\n";
		$text .= "</tr><tr>\n";
		$text .= "<td colspan=2 align=center><input type=submit name=submit></td>\n";
		$text .= "</tr><tr>\n";
		$text .= "<td colspan=2 align=center>\n";
		$text .= "If you don't have a login, please \n";
		$text .= "<a href=\"".$cgi->script_name."/register/\">register</a>.</td>\n";
		$text .= "</tr>\n";
		$text .= "</table></center>\n";
		$text .= "</form>\n";
	}
	$self->tag("text", $text );
}

sub do_maint
{
	my $self = shift;

	# must be logged in to use this function
	if (( ! defined $self->{remote_user}) or ! $self->{remote_user}) {
		my $text = "You must be\n";
		$text .= "<a href=\"\"></a>logged in</a>\n";
		$text .= "to use this function.";
		$self->tag("text", $text );
		return;
	}

	# if new password is provided, process it
	if ( $self->{path}[1] eq "change-pw" ) {
		if ( $self->check_params( "pw1", "pw2" )) {
		} else {
		}
		return
	}

	# maintenance menu
	debug and print STDERR "Slauth::User::Web::interface: "
		."login form\n";
}


#
# utility functions
#

# handle a redirect to a new URL
sub redirect
{
	my $self = shift;
	my $url = shift;
	if ( defined $self->{r}) {
		# mod_perl mode
		my $r = $self->{r};
		if ( defined $self->{cookies}) {
			my $cookie;
			foreach $cookie ( @{$self->{cookies}}) {
				$r->err_headers_out->add(
					'Set-Cookie' => $cookie);
			}
		}
		$r->headers_out->set( "Location" => $url );
		$r->status(REDIRECT);
		return REDIRECT;
	} else {
		# CGI mode
		my $cgi = $self->{cgi};
		if ( defined $self->{cookies}) {
			my $cookie;
			foreach $cookie ( @{$self->{cookies}}) {
				
				print $cgi->header( -cookie => $cookie );
			}
		}
		print $cgi->redirect( $cgi->self_url."/" );
		return;
	}
}

# get the original request URL, even if we're processing an error document
sub self_url
{
	my $self = shift;
	if ( defined $self->{r}) {
		# mod_perl mode
		my $r = $self->{r};

		# figure out where the request really came from
		my $req_str = $r->the_request;
		$req_str =~ s/^[^\s]*\s+//;
		$req_str =~ s/\s+[^\s]*$//;

		return $r->construct_url($req_str);
	} else {
		# CGI mode - this is ineffective for error documents
		my $cgi = $self->{cgi};
		return $cgi->self_cgi;
	}
}

# mod_perl response handler
sub handler
{
	my $r = shift;
	my $web = new Slauth::User::Web ( "request" => $r );
	return $web->interface;
}

1;
