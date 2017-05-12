package OpenInteract;

# $Id: OpenInteract.pm,v 1.55 2004/09/28 16:10:37 lachoy Exp $

use strict;
use Apache::Constants qw( :common :remotehost :response );
use Apache::Request;
use Data::Dumper      qw( Dumper );

$OpenInteract::VERSION  = '1.62';

# Generic separator used in display

my $SEP = '=' x 30;

# Keep track of what's been require'd

my %REQ = ();


sub handler ($$) {
    my ( $class, $apache ) = @_;

    # Create the big cheese object (aka, "Big R") and populate with some
    # basic info

    my $R = eval { $class->setup_request( $apache ) };
    if ( $@ ) {
        $class->send_html( $apache, $@ );
        return OK;
    }
    $R->DEBUG && $R->scrib( 1, "\n\n$SEP\nRequest started:", scalar localtime( $R->{time} ), "\n",
                               "path: (", $apache->parsed_uri->path, ") PID: ($$)" );

    # Go through all of our important steps -- we setup the basic
    # environment, generate the content and run additional routines after
    # the content has completed for tracking (session, cookies, etc.)
    #
    # If there is a problem with a routine it will die with the
    # appropriate Apache constant (usually OK) and if we find it we force
    # it to numeric context and return it.

    my ( $page );
    eval {
        $class->setup_server_interface( $R, $apache );
        $class->setup_cache( $R );
        $class->parse_uri( $R );
        $class->find_action_handler( $R );
        $class->check_database( $R );
        $class->setup_cookies_and_session( $R );
        $class->setup_authentication( $R );
        $class->setup_theme( $R );
        $page = $class->run_content_handler( $R );
        $class->finish_cookies_and_session( $R );
    };
    if ( $@ ) {
        warn " --EXITED WITH ERROR from main handler eval block\nError: $@\n";
        return $class->bail( $@ );
    }

    if ( $R->{page}{send_file} ) {
        $class->send_static_file( $R );
    }
    elsif ( my $redirect_url = $R->{page}{http_redirect} ) {
        my $apr = $R->apache;
        $apr->no_cache(1);
        $apr->headers_out->set( Location => $redirect_url );
        $apr->status( REDIRECT );
        $apr->send_http_header;
    }
    else {
        $class->send_html( $apache, $page, $R );
    }

    $class->cleanup( $R );
    return OK;
}

sub bail {
    my ( $class, $msg ) = @_;
    $msg = $msg + 0;   # force scalar to numeric
    return $msg;
}


# Setup the OpenInteract::Request object

sub setup_request {
    my ( $class, $apache ) = @_;

    # Read the stash class from our httpd.conf and grab the config
    # object

    my $STASH_CLASS = $apache->dir_config( 'OIStashClass' );
    unless ( $REQ{ $STASH_CLASS } ) {
        eval "require $STASH_CLASS";
        if ( $@ ) {
            $apache->child_terminate;
            die "Cannot require stash class ($STASH_CLASS) -- ",
                "fatal event, will terminate Apache child\n";
        }
        $REQ{ $STASH_CLASS }++;
    }
    my $C = $STASH_CLASS->get_stash( 'config' );
    unless ( ref $C and scalar keys %{ $C } ) {
        $apache->child_terminate;
        die "Cannot find configuration object from stash class ($STASH_CLASS) -- ",
            "fatal event, will terminate Apache child\n";
    }

    # Create the base request object that contains other objects and
    # info

    my $REQUEST_CLASS = $C->{server_info}{request_class};
    unless ( $REQ{ $REQUEST_CLASS } ) {
        eval "require $REQUEST_CLASS";
        if ( $@ ) {
            $apache->child_terminate;
            die "Cannot require request class ($REQUEST_CLASS) -- ",
                "fatal event, will terminate Apache child\n";
        }
        $REQ{ $REQUEST_CLASS }++;
    }
    my $R = $REQUEST_CLASS->instance;
    $R->{stash_class} = $STASH_CLASS;
    $R->{pid}         = $$;
    $R->{time}        = time;
    return $R;
}


# The Apache::Request subclasses the main Apache object and has
# additional methods to parse GET/POST data, including file
# uploads. Stash this object then get the server name and remote IP
# address -- if you're using a proxy, be sure that this has been
# passed from the front end server using mod_proxy_add_forward

sub setup_apache { my $c = shift; return $c->setup_server_interface( @_ ) }

sub setup_server_interface {
    my ( $class, $R, $apache ) = @_;
    my $apr = Apache::Request->new( $apache );
    $R->stash( 'apache', $apr );

    my $srv = $apr->server;
    $R->{server_name} = $srv->server_hostname;
    $R->DEBUG && $R->scrib( 1, "Server hostname set to $R->{server_name}" );

    $R->{remote_host} = $apr->connection->remote_ip();
    $R->DEBUG && $R->scrib( 1, "Request coming from $R->{remote_host}" );
    return;
}


# Create the cache object if we're supposed to

sub setup_cache {
    my ( $class, $R ) = @_;
    my $CONFIG = $R->CONFIG;
    my $cache_info = $CONFIG->{cache_info}{data};
    if ( ! $R->cache and $cache_info->{use} ) {
        my $cache_class = $cache_info->{class};
        eval "require $cache_class";
        if ( $@ ) {
            $R->scrib( 0, "Cannot include cache class [$cache_class]: $@\n",
                          "Continuing with operation..." );
            return;
        }
        $R->DEBUG && $R->scrib( 1, "Using cache and setting up with [$cache_class]" );
        my $cache = $cache_class->new( $CONFIG );
        $R->stash( 'cache', $cache );
    }
    return;
}


# Parse the URL into pieces, stroing everything relevant in
# $R->{path}. Also find the 'action' specified in the URL -- we use
# this to find a handler in the action table. Note that if the first
# item is actually a directive (such as 'Popup'), then we shift it off
# and it in $R->{ui}{directive} so the UI handler knows it's
# around. After we do this the $R->{path}{current} should be
# consistent, with the action as the first member.

sub parse_uri {
    my ( $class, $R, $uri ) = @_;

    my $apache = $R->apache;

    # Get the Apache::URI object and put it in $R
    unless ( $uri ) {
        $uri = $apache->parsed_uri;
    }

    # TODO: Do we EVER retrieve the URI object from the stash? Why put
    # it there?

    $R->stash( 'uri', $uri );

    # Get the path info from the URL and put it in $R; we save it twice
    # so we can shift items from one and still keep the original; we
    # also get the action name from the first item in the path

    my $location = $apache->location;
    my $path = $uri->path;
    $R->DEBUG && $R->scrib( 1, "Original path: ($path)" );
    if ( $location ne '/' ) {
        $path =~ s/^$location//;
        $R->{path}{location} = $location;
        $R->DEBUG && $R->scrib( 1, "Modified path by removing ($location): ($path)" );
    }
    my @choices = split /\//, $path;
    shift @choices;
    $R->DEBUG && $R->scrib( 1, "Items in the path: ", join( " // ", @choices ) );
    my @full_choices       = @choices;
    $R->{path}{current}  = \@choices;
    $R->{path}{full}     = \@full_choices;

    # If the first item is a directive, remove it and save it for the ui
    # handler; otherwise it's as if it never existed

    if ( $R->CONFIG->{page_directives}{ $R->{path}{current}->[0] } ) {
        $R->{ui}{directive} = shift @{ $R->{path}{current} };
        $path = '/' . join( '/', @{ $R->{path}{current} } );
    }
    $R->{ui}{action} = $R->{path}{current}->[0];
    $R->DEBUG && $R->scrib( 1, "Action found from URL: $R->{ui}{action}" );

    # Note that $path might have been modified if the first item was a
    # directive

    $R->{path}{original} = $path;
    $R->{path}{original} .=  '?' . $uri->query  if ( $uri->query );
    $R->DEBUG && $R->scrib( 1, "Original path/query string set to: $R->{path}{original}" );
    return;
}


# Match up the URL path to the UI action (Conductor) and store the
# relevant information in $R

sub find_action_handler {
    my ( $class, $R ) = @_;
    ( $R->{ui}{class}, $R->{ui}{method} ) = $R->lookup_conductor( $R->{ui}{action} );
    unless ( $R->{ui}{class} ) {
        $R->scrib( 0, " Conductor not found; displaying oops page." );
        eval { $R->throw({ code       => 301,
                           type       => 'file',
                           user_msg   => "Bad URL",
                           system_msg => "Cannot find conductor for $R->{ui}{action}",
                           extra      => { url => $R->{path}{original} } }) };
        if ( $@ ) {
            $class->send_html( $R->apache, $@, $R );
            die OK . "\n";
        }
    }
    $R->DEBUG && $R->scrib( 1, "Found $R->{ui}{class} // $R->{ui}{method} for conductor" );
    return;
}

# Ensure our main database is up, otherwise bail.

sub check_database {
    my ( $class, $R ) = @_;
    my $db = $R->db( 'main' );
    eval {
        unless ( $db ) {
            $R->apache->child_terminate;
            die "Database not found -- fatal event, will terminate Apache child\n";
        }
        $R->DEBUG && warn "Found item: ", ref( $db ), "\n";
        $db->ping;
    };
    if ( $@ ) {
        $R->apache->child_terminate;
        $R->scrib( 0, "Cannot ping database -- fatal event, will terminate Apache child" );
        my $error_msg = $R->throw({ code => 11 });
        $class->send_html( $R->apache, $error_msg, $R );
        die OK . "\n";
    }
    return;
}

sub setup_cookies_and_session {
    my ( $class, $R ) = @_;
    eval {
        $R->DEBUG && $R->scrib( 2, "Trying to use cookie class: ", $R->cookies );
        $R->cookies->parse;
        $R->DEBUG && $R->scrib( 2, "Cookies in:", Dumper( $R->{cookie}{in} ) );
        $R->DEBUG && $R->scrib( 2, "Trying to use session class: ", $R->session );
        $R->session->parse;
    };
    if ( $@ ) {
        $class->send_html( $R->apache, $@, $R );
        die OK . "\n";
    }
    return;
}


sub finish_cookies_and_session {
    my ( $class, $R ) = @_;
    eval {
        $R->session->save;
        $R->cookies->bake;
        $R->DEBUG && $R->scrib( 2, "Cookies out:",
                                   join(" // ", map { $_->name . ' = ' . $_->value }
                                                    values %{ $R->{cookie}{out} } ) );
    };
    if ( $@ ) {
        $class->send_html( $R->apache, $@, $R );
        die OK . "\n";
    }
    return;
}


# Call the various user/group authentication routines

sub setup_authentication {
    my ( $class, $R ) = @_;
    my ( $error_msg );
    if ( my $auth_class = $R->auth ) {
        eval {
            $auth_class->user;
            $auth_class->group;
            $auth_class->is_admin;
            $auth_class->custom_handler;
        };
        $error_msg = $@;
    }
    else {
        $error_msg = "Authentication cannot be setup! Please ensure 'auth' " .
                     "is setup in your server configuration under 'system_alias'";
    }
    if ( $error_msg ) {
        $class->send_html( $R->apache, $error_msg, $R );
        die OK . "\n";
    }

    my $login_info = $R->CONFIG->{login};
    return undef unless ( $login_info->{required} );
    return undef if ( $R->{auth}{logged_in} );
    my $url_requires_login =
        $class->url_requires_login( $R->{path}{original},
                                    $login_info->{required_skip} );
    return undef unless ( $url_requires_login );
    return $class->required_login_not_found( $R );
}


# True if the URL requires login (that is, it DOESN'T match a member
# of \@url_to_skip)

sub url_requires_login {
    my ( $class, $url, $url_to_skip ) = @_;
    return 1 unless ( $url_to_skip );
    my @urls_to_check = ( ref $url_to_skip eq 'ARRAY' )
                          ? @{ $url_to_skip } : ( $url_to_skip );
    my $url_skip = 0;
    foreach my $url_check ( @urls_to_check ) {
        next unless ( $url_check );
        $url_skip++ if ( $url =~ /$url_check/ );
    }
    return ( ! $url_skip );
}

# Reset the URL to 'login.required_url' (could this have side
# effects?)

sub required_login_not_found {
    my ( $class, $R ) = @_;
    my $required_url = $R->CONFIG->{login}{required_url};
    unless ( $required_url ) {
        $R->scrib( 0, "You have 'login.required' enabled so I'm ensuring ",
                      "that all users have a login, but you don't have ",
                      "'login_required_url' set to a URL where I should ",
                     "send them. Ignoring login requirement setting..." );
        return undef;
    }
    my $host = $R->{server_name};
    my $full_url = join( '', 'http://', $host, $required_url );
    my $uri = Apache::URI->parse( $R->apache, $full_url );
    $R->DEBUG && $R->scrib( 1, "Resetting request URL to '$full_url' (composed ",
                               "of host '$host' and path '$required_url') since ",
                               "login required and none found" );

    # This is available for the login page to set in a hidden variable
    # of its choosing; it's also used in the template plugin method
    # 'return_url()' called by the login box...

    $R->{path}{login_fail} = $R->{path}{original};
    return $class->parse_uri( $R, $uri );
}


# Create the theme used; note that logged-in users can choose
# their own, but anonymous users have to stick with 'main'. Each
# UI handler (conductor) can decide what to do with the object, but
# for now we won't try to fetch all the properties or anything

sub setup_theme {
    my ( $class, $R ) = @_;
    my $C = $R->CONFIG;
    my $theme_refresh = $R->CONFIG->{session_info}{cache_theme};
    if ( $theme_refresh > 0 ) {
        if ( my $theme = $R->{session}{_oi_cache}{theme} ) {
            if ( time < $R->{session}{_oi_cache}{theme_refresh_on} ) {
                $R->DEBUG && $R->scrib( 1, "Got theme from session ok" );
                $R->{theme} = $theme;
                return;
            }
            $R->DEBUG && $R->scrib( 1, "Theme session cache expired; refreshing from db" );
        }
    }

    $R->{theme} = ( $R->{auth}{user} and $R->{auth}{user}{theme_id} )
                    ? eval { $R->{auth}{user}->theme }
                    : eval { $R->theme->fetch( $C->{default_objects}{theme} ) };
    if ( $@ ) {
        my $ei = SPOPS::Error->get;
        OpenInteract::Error->set( $ei );
        $R->throw({ code => 404 });
        $R->scrib( 0, "Error! Cannot retrieve theme! ( Class: ", $R->theme, ")",
                      "with error ($@ / $ei->{system_msg}) Help!" );
        my $admin_email = $C->{mail}{admin_email} || $C->{admin_email};
        my $error_msg = <<THEMERR;
Fundamental part of OpenInteract (themes) not functioning; please contact the
system administrator (<a href="mailto:$admin_email">$admin_email</a>).
THEMERR
        $class->send_html( $R->apache, $error_msg, $R );
        die OK . "\n";
    }

    # Find all the properties before we potentially cache

    $R->{theme}->discover_properties;
    if ( $theme_refresh > 0 ) {
        $R->{session}{_oi_cache}{theme} = $R->{theme};
        $R->{session}{_oi_cache}{theme_refresh_on} = time + ( $theme_refresh + 60 );
        $R->DEBUG && $R->scrib( 1, "Set theme to session cache, expires ",
                                   "in [$theme_refresh] minutes" );
    }
    return;
}


# Runs the content handler -- this should either return the full page
# ready for display or put the information into $R necessary to send a
# static (non-HTML) file

sub run_content_handler {
    my ( $class, $R ) = @_;
    my ( $ui_class, $ui_method ) = ( $R->{ui}{class}, $R->{ui}{method} );
    $R->DEBUG && $R->scrib( 1, "Trying the conductor: <<$ui_class/$ui_method>>" );
    return $ui_class->$ui_method();
}


# Send a static (non-html/text) file to the user; note that the
# content type should already have been set -- normally this is done
# automatically by Apache, particularly if the URL ends with a known
# filetype

sub send_static_file {
    my ( $class, $R ) = @_;
    my $file_spec = $R->{page}{send_file};
    my ( $file_size );
    my ( $fh );

    # File is a handle...

    if ( ref $file_spec ) {
        $fh = $file_spec;
        my $default_type = 'application/octet-stream';
        unless ( $R->{page}{content_type} ) {
            $R->scrib( 0, "No content type set for filehandle to send, ",
                          "using default '$default_type'\n" );
            $R->{page}{content_type} = $default_type;
        }
        $file_size = (stat $fh)[7];
        $R->DEBUG && $R->scrib( 1, "Sending filehandle of size",
                               "($file_size) and type",
                               "($R->{page}{content_type})" );
    }

    # File is a filename...
    else {
        $fh = Apache->gensym;
        eval { open( $fh, $file_spec ) || die $! };
        if ( $@ ) {
            $R->scrib( 0, "Cannot open static file from filesystem ($file_spec): $@" );
            return NOT_FOUND;
        }
        $file_size = $R->{page}{send_file_size}
                     || (stat $file_spec)[7];
        $R->DEBUG && $R->scrib( 1, "Sending file ($file_spec) of size",
                                "($file_size) and type",
                                "($R->{page}{content_type})" );
    }
    $R->apache->headers_out->{'Content-Length'} = $file_size;
    $R->apache->send_http_header( $R->{page}{content_type} );
    $R->apache->send_fd( $fh );
    close( $fh );
}


# Send plain html (or text) to the browser

sub send_html {
    my ( $class, $apache, $content, $R ) = @_;
    if ( ref $R ) {
        unless ( $R->CONFIG->{no_promotion} ) {
            $apache->headers_out->{'X-Powered-By'} =
                                   "OpenInteract $OpenInteract::VERSION";
        }
    }
    my $content_type = $R->{page}{content_type} ||
                       $apache->content_type ||
                       'text/html';
    $content_type = ( $content_type eq 'httpd/unix-directory' )
                      ? 'text/html' : $content_type;
    $apache->send_http_header( $content_type );
    $apache->print( $content );
}


# Do any necessary cleanup -- logging, remove stash entries, etc.

sub cleanup {
    my ( $class, $R ) = @_;

    # Wrap this in an eval so it won't bomb if 0.56 isn't installed

    eval { SPOPS::Exception->clear_stack };

    $R->DEBUG && $R->scrib( 2, "\n\nErrors: ", Dumper( $R->error_object->report ), "\n" );
    $R->error->clear;
    $R->error_object->clear_listing;
    $R->DEBUG && $R->scrib( 1, "\nRequest done:", scalar localtime, "\n",
                               "path: ($R->{path}{original}) PID: ($$)\n",
                               "from: ($R->{remote_host})\n$SEP\n" );
    $R->finish_request;
    return;
}

1;

__END__

=head1 NAME

OpenInteract - mod_perl handler to process all OpenInteract requests

=head1 DESCRIPTION

This documentation is for the OpenInteract Apache content handler. For
general information about OpenInteract, see
L<OpenInteract::Intro|OpenInteract::Intro>.

This content handler creates the
L<OpenInteract::Request|OpenInteract::Request> object and farms
requests out to all the relevant handlers -- cookies, session,
authentication, themes, etc.

We walk through a number of class methods here. They are probably
self-evident by checking out the code, but just to be on the safe
side.

=over 4

=item *

B<setup_request( $apache )>: Retrieve the StashClass from the Apache
config, grab the Config object from the StashClass, and
create/retrieve the L<OpenInteract::Request|OpenInteract::Request>
object.

Return: C<$R> (an L<OpenInteract::Request|OpenInteract::Request>)

On error: C<die> with error message.

=item *

B<setup_apache( $R, $apache )>: Create the
L<Apache::Request|Apache::Request> object and store it in C<$R>. We
reuse this object throughout the request so we should not have any
issues with POST values being empty on a second read.

Return: nothing

On error: Send error information to user via C<send_html()> then
C<die> with Apache return code (e.g., 'OK' )

=item *

B<setup_cache( $R )>: Create the cache object if we are supposed to
use it

Return: nothing

On error: Send error information to user via C<send_html()> then
C<die> with Apache return code (e.g., 'OK' )

=item *

B<parse_uri( $R )>: Parse the URL and decide which conductor (UI)
should take care of the request

Return: nothing

On error: Send error information to user via C<send_html()> then
C<die> with Apache return code (e.g., 'OK' )

=item *

B<setup_cookies_and_session( $R )>: Get the cookies and retrieve a
session if it exists.

Return: nothing

On error: Send error information to user via C<send_html()> then
C<die> with Apache return code (e.g., 'OK' )

=item *

B<setup_authentication( $R )>: Authenticate the user and get the
groups the user belongs to, plus set for this request whether the user
is an administrator. Also run the custom authentication handler as
defined in the server configuration.

If the 'login.required' server configuration key is a true value we
ensure that there's a legitimate user logged in. If there's no login
we call the 'url_requires_login()' class method passing the requested
URL and the arrayref of URLs in the 'login.required_skip' server
configuration key.

If that method indicates that the URL does require a login we call the
class method 'required_login_not_found()', passing C<$R> as the sole
argument. That method is responsible for resetting the URL in the
request to that specified in 'login.required_url'.

Return: nothing

On error: Send error information to user via C<send_html()> then
C<die> with Apache return code (e.g., 'OK' )

=item *

B<setup_theme( $R )>: Create the theme that is used throughout the
request and stored in C<$R-E<gt>{theme}>.

Return: nothing

On error: Send error information to user via C<send_html()> then
C<die> with Apache return code (e.g., 'OK' )

=item *

B<run_content_handler( $R )>: Run the content handler which generates
the full page.

Return: nothing

On error: Send error information to user via C<send_html()> then
C<die> with Apache return code (e.g., 'OK' )

=item *

B<finish_cookies_and_session( $R )>: Save the session and bake the
cookies (put them into outgoing headers).

Return: nothing

On error: Send error information to user via C<send_html()> then
C<die> with Apache return code (e.g., 'OK' )

=item *

B<send_html( $apache, $page, $R )>: Send the http header(s) and HTML
for the page content.

=item *

B<send_static_file( $R )>: If a static file is specified (if a person
requests a PDF file), then send it.

=item *

B<cleanup( $R )>: Cleanup the request object and stash class.

=back

Since all of the above are class methods, you can subclass
L<OpenInteract|OpenInteract> so you override one or more of the above
methods.

=head1 NOTES

If you get an error with something like:

Can't locate object method "cookies" via package "OpenInteract::Request"
at /usr/lib/perl5/site_perl/5.6.1/OpenInteract.pm line 226.

This likely means that the C<OpenInteract::Request::setup_aliases()>
wasn't run. Typically this is run in the PerlChildInitHandler when an
Apache child is first created. This points to a larger problem if it
is not run. (What exactly is that larger problem? Still working on
that...)

=head1 TO DO

Nothing known

=head1 BUGS

None known

=head1 COPYRIGHT

Copyright (c) 2001-2002 intes.net, inc.. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters <chris@cwinters.com>
