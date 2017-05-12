# $Id: Application.pm,v 1.30 2003/05/11 01:54:03 andreychek Exp $

package OpenPlugin::Application;

use strict;

$OpenPlugin::Application::VERSION = sprintf("%d.%02d", q$Revision: 1.30 $ =~ /(\d+)\.(\d+)/);

use OpenPlugin();
use CGI::Application 2.6 qw();
use base qw( CGI::Application );

# This sub overrides one provided with CGI::Application.  It's job is to return
# a query object.  The one provided with CGI::App returns a CGI.pm object --
# but we want to return an OpenPlugin object.
sub cgiapp_get_query {
    my $self = shift;

    my @keys = $self->param;
    my %params;

    # Gather the parameters sent to us in the new() constructor
    foreach my $key ( @keys ) {
        $params{$key} = $self->param( $key );
    }

    return OpenPlugin::Wrapper->new( %params );
}

# This is meant to be an alias for CGI::App's query() method
sub OP {
    my $self = shift;

    $self->SUPER::query( @_ );

}

package OpenPlugin::Wrapper;

@OpenPlugin::Wrapper::ISA = qw( OpenPlugin );

# This is a wrapper module to make OpenPlugin behave like CGI.pm.  This is
# soley to get CGI::Application to work properly, as it assumes you are using
# CGI.pm.  If anyone has thoughts on a better way to do this, I would certainly
# be glad to hear them :-)

# When called from CGI::Application, this method act's like the param() in
# CGI.pm.  Otherwise, it just passes the request onto OpenPlugin.
sub param {
    my $self   = shift;
    my @params = @_;

    if( (caller)[0] eq "CGI::Application" ) {
        return $self->SUPER::param->get_incoming( @params );
    }
    else {
        return $self->SUPER::param( @params );
    }
}

# When called from CGI::Application, this method act's like the same one from
# CGI.pm.  Otherwise, it just passes the request onto OpenPlugin.
sub header {
    my $self   = shift;
    my @params = @_;

    if( (caller)[0] eq "CGI::Application" ) {
        return $self->SUPER::httpheader->send_outgoing( @params );
    }
    else {
        return $self->SUPER::httpheader( @params );
    }
}

1;

__END__

=pod

=head1 NAME

OpenPlugin::Application - A subclass of CGI::Application, meant to help you
create reusable web applications.

=head1 SYNOPSIS

 # Example from OpenThought's Demo.pm

 package Demo;
 use base "OpenPlugin::Application";
 sub setup {
     my $self = shift;
     $self->run_modes(
        'mode1' => 'init_demo',
        'mode2' => 'get_os_list',
        'mode3' => 'get_os_info',
     );
     $self->start_mode( 'mode1' );
     $self->mode_param('run_mode');
 }
 sub init_demo   { ... }
 sub get_os_list { ... }
 sub get_os_info { ... }
 1;

 # Example from OpenThought's demo.pl

 #!/usr/bin/perl -wT
 use strict;
 my $r = shift;
 my $demo = Demo->new( PARAMS => {
                    config  => { src    => "/path/to/OpenPlugin.conf" },
                    request => { apache => $r },
 });

 $demo->run();

=head1 DESCRIPTION

OpenPlugin::Application is built on Jesse Erlbaum's popular L<CGI::Application>
module.  OpenPlugin::Application is simply a subclass of CGI::Application.
Jesse says the following about CGI::Application:

"CGI::Application is intended to make it easier to create sophisticated,
reusable web-based applications. This module implements a methodology which, if
followed, will make your web software easier to design, easier to document,
easier to write, and easier to evolve."

How does it do this?  Jesse goes on to say:

"The guiding philosophy behind CGI::Application is that a web-based application
can be organized into a specific set of "Run-Modes." Each Run-Mode is roughly
analogous to a single screen (a form, some output, etc.). All the Run-Modes are
managed by a single "Application Module" which is a Perl module. In your web
server's document space there is an "Instance Script" which is called by the
web server"

The biggest difference between CGI::Application and OpenPlugin::Application is
that query object they both use; one is designed to use CGI.pm, the other
OpenPlugin.  Generally speaking, everything in the <CGI::Application
documentation|CGI::Application> still applies.  Any differences will be noted
in this document.

It is not necessary to use OpenPlugin::Application in order to build web
applications using OpenPlugin.  This plugin is meant to be for your
convenience -- to help you structure your web applications in a manner which
makes sense, and is reusable.

=head1 USAGE

Just like with CGI::Application, you first need to develop an "instance
script".  That is the .pl file which your browser will be requesting.  An
example of one might look like:

 #!/usr/bin/perl -wT
 use MyWebApp();

 my $web_app = MyWebApp->new( PARAMS => {
                    config => { src => "/path/to/OpenPlugin.conf" },
                  });
 $web_app->run();

This script simply simply "uses" C<MyWebApp>, your application module, and then
calls the C<new> constructor.

Notice that we're using the C<new()> constructor to pass in parameters
which OpenPlugin needs in order to initialize.  OpenPlugin::Application will
use those parameters to create a new OpenPlugin object.

So, in a case where you were using OpenPlugin's Apache (mod_perl) drivers, you
might do something like the following:

 #!/usr/bin/perl -wT
 use MyWebApp();

 my $r = shift;
 my $web_app = MyWebApp->new( PARAMS => {
                            config  => { src    => "/path/to/OpenPlugin.conf" },
                            request => { apache => $r },
                        });
 $web_app->run();

By passing in the C<$r> Apache object, the above enables OpenPlugin's Apache
drivers to function properly.

Within the actual MyWebApp.pm module, the syntax should be identical to a
typical module written in CGI::Application, with just a few exceptions:

=over 4

=item * OpenPlugin::Application, not CGI::Application

The second line of the module will read C<use base "OpenPlugin::Application";>
instead of C<use base "CGI::Application";>.

=item * OP() method available

A method called C<OP> was created as an alias for C<query>.  You may use the
two interchangably.

=item * Use OpenPlugin's header/cookie plugins

CGI::Application offers methods to handle headers for you.  While these will
work, I highly recommend using OpenPlugin's HttpHeader and Cookie plugins
instead, these offer far more flexibility and functionality than do the ones
provided with CGI::Application.

When using OpenPlugin, the HttpHeader C<send_outgoing()> method will be called
for you, you just need to add your headers to the outgoing queue by calling
$OP->httpheader->set_outgoing({ header_name => header_value }).  Of course,
this is just the typical Httpheader Plugin usage, see the L<Httpheader
documentation|OpenPlugin::Httpheader> for more information.

=back

Here is an example of how you might build the MyWebApp application:

 package MyWebApp;
 use base 'OpenPlugin::Application';
 use strict;

 # This method is used to define what run_modes are available, and gives you an
 # opportunity to do any other setup work, like initiating database connections
 sub setup {
     my $self = shift;

     # Get the OpenPlugin object.  This is an alias for $self->query;
     my $OP = $self->OP;

     $self->start_mode('mode1');
     $self->run_modes(
             'mode1' => 'show_login_screen',
             'mode2' => 'do_login',
             'mode3' => '...'
     );

     # Connect to database using OpenPlugin's datasource plugin
     $self->param('mydbh' => $OP->datasource->connect('MyDataSourceName'));

     # Retrieve our session
     my $session_id = $OP->param->get_incoming( 'session_id' );
     $self->param('session' => $OP->session->fetch( $session_id ));
 }

 # This method is run after your run mode is finished executing
 sub teardown {
     my $self = shift;
     my $OP   = $self->OP;

     # Disconnect when we're done
     #   (this is for example purposes only; often when running under mod_perl,
     #   you would not disconnect your datasources at the end of a request)

     $OP->datasource->disconnect('MyDataSourceName');
 }

 sub show_login_screen {
     my $self = shift;

     # Retrieves an HTML::Template object
     my $tmpl_obj = $self->load_tmpl('login_template.html');

     # Return the data we want sent to the browser
     return $tmpl_obj->output;
 }

 sub do_login {
     my $self = shift;
     my $OP   = $self->OP;
     my $tmpl_obj;

     my $username = $OP->param->get_incoming('username');
     my $password = $OP->param->get_incoming('password');

     # If the authentication was successful, set a cookie, then display a menu
     if( $OP->authenticate->authenticate( $username, $password )) {

         # Set a cookie
         $OP->cookie->set_outgoing({
                                name  => 'username',
                                value => $username,
                            });

         $tmpl_obj = $self->load_tmpl('menu_template.html');
     }

     # If the authentication was not successful, display an error message
     else {
         $tmpl_obj = $self->load_tmpl('error_template.html');
     }

     return $tmpl_obj->output;
 }

=head1 BUGS

None known.

=head1 TO DO

Nothing known.

=head1 SEE ALSO

L<OpenPlugin>, L<CGI::Application>

=head1 COPYRIGHT

Copyright (c) 2001-2003 Eric Andreychek. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Eric Andreychek <eric@openthought.net>

=cut
