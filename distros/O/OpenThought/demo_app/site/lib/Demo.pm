package Demo;

use strict;
use base 'OpenPlugin::Application';
use OpenThought();

# The setup method (just like CGI::Application).  This method is called by
# OpenPlugin::Application's new() method, and is used to set up various
# parameters, including the run_modes.
sub setup {
    my $self = shift;

    # Define our run modes.  In the left column is the run mode name, as sent
    # to us by the browser.  On the right is the subroutine to execute when we
    # receive a particular run mode.
    $self->run_modes(
            'mode1'           => 'init_demo',
            'mode2'           => 'get_os_list',
            'mode3'           => 'get_os_info',
            'session_expired' => 'session_expired',
    );

    # The default run mode, this mode is run if we aren't explicitely sent one.
    $self->start_mode('mode1');

    # Define what the name of our run mode param is
    $self->mode_param('run_mode');

}

# If implemented, this method is called right before the setup() method.  This
# can be used as an initialization hook, which can improve the OO
# characteristics of your application.  This method receives, as it's
# parameters, all the arguments which were sent to the new() method.
sub cgiapp_init {
    my $self = shift;
    my $OP   = $self->OP;

    # The param() method is an accessor method for OpenPlugin::Application.  In
    # this case, we are creating a new property -- an OpenThought object.
    $self->param( 'OpenThought' => OpenThought->new( $OP ) );

    # Take the session_id passed to us by the browser, and fetch the session
    # data it is associated with
    my $session = $OP->session->fetch(
                $OP->param->get_incoming('session_id'));

    # Make the session data a property of this class
    $self->param( 'session' => $session );

}

# This sub is run immediatly before the actual run_mode sub and after "setup",
# and is capable of modifying the run_mode if necessary.  This should not be
# called manually, it will be called by CGI::App for us.
sub cgiapp_prerun {
    my ( $self, $run_mode ) = @_;

    # Don't execute the next lines of code if we are just loading the app
    return if ( $self->get_current_runmode eq "mode1" );

    # Verify that the session is valid -- if it is not, change the run mode to
    # 'session_expired'
    unless( $self->param('session') ) {
        $self->prerun_mode('session_expired');
    }
}

# Return a javascript popup message about the expired session
sub session_expired {
    my $self = shift;

    my $data;
    my $msg = "Your session has expired!";
    my $js = qq{alert("$msg");};

    $data->{javascript} = $js;
    return $self->param( 'OpenThought' )->serialize( $data );
}

# Our first (and default) run mode -- this method initializes the pieces of the
# demo app
sub init_demo {
    my $self = shift;
    my $OP   = $self->OP;
    my $OT   = $self->param('OpenThought');

    return $OT->event( init => sub { return $OT->init       },
                       ui   => sub { return $self->init_ui  },
                       #data => sub { return $self->default_data_handler },

                       # The "data" handler above isn't necessary when using
                       # run modes via OpenPlugin::Application (as this demo
                       # does), as this particular subroutine will never be
                       # called when a run mode is sent in as a parameter
    );
}


sub init_ui {
    my $self = shift;

    my $template;

    # load_tmpl() uses HTML::Template to load a template document
    $template = $self->load_tmpl(
            "${Demo::OpenThoughtAppsPath}/templates/demo/demo-template.html");

    return $template->output;
}

# This is the second run mode.  If we are here, it means the user clicked the
# button labeled 'Get OS List!'.
sub get_os_list {
    my $self = shift;

    my $field_data;

    # Here we define values which will go into an HTML select element.  An
    # array of arrays is used to create the data for the element.  The hash key
    # 'selectlist' is the name of the select element in the HTML.  In the
    # following array, the data is defined in pairs.  In the left column (where
    # the first piece of data is labeled 'AIX'), this text will be visibly
    # displayed in the select element.  The data in the right column (where the
    # first piece of data is 'aix') will be the value sent to the server if the
    # user clicks that option.
    $field_data->{'selectlist'} = [
                                    ['AIX'     , 'aix'     ],
                                    ['BeOS'    , 'beos'    ],
                                    ['Emacs'   , 'emacs'   ],
                                    ['HP UX'   , 'hpux'    ],
                                    ['Linux'   , 'linux'   ],
                                    ['Netware' , 'netware' ],
                                    ['OS/2'    , 'os2'     ],
                                    ['Plan 9'  , 'plan9'   ],
                                    ['Solaris' , 'solaris' ],
                                    ['Windows' , 'windows' ],
                                   ];

    # Send the data we just defined to the browser, and focus the form element
    # named 'selectlist'
    return $self->param('OpenThought')->serialize({
                                            fields => $field_data,
                                            focus  => "selectlist",
                                         });
}

# This is our third run mode.  If we are here, the user clicked one of the
# items in the select list.
sub get_os_info {
    my $self = shift;
    my $OP   = $self->OP;
    my $field_data;

    # We had already assigned the items in the select list a value (in run mode
    # 2), and now we've been sent that value.  Lets figure out which one was
    # clicked, and respond appropriatly.
    my $param = $OP->param->get_incoming('fields')->{'selectlist'};

    if ( $param eq 'aix' ) {

        $field_data = {
            'os'            => 'AIX',
            'creator'       => 'IBM',
            'notes'         => 'None',
            'free'          => 'false',
            'cool'          => 'false',
            'goodlooking'   => 'false',
        };
    }

    elsif ( $param eq 'beos' ) {

        $field_data = {
            'os'            => 'BeOS',
            'creator'       => 'Be, Inc',
            'notes'         => 'Good for Multimedia, bad driver support',
            'free'          => 'true',
            'cool'          => 'true',
            'goodlooking'   => 'true',
        };
    }

    elsif ( $param eq 'emacs' ) {

        $field_data = {
            'os'            => 'Emacs',
            'creator'       => 'RMS',
            'notes'         => 'Wow thats big',
            'free'          => 'true',
            'cool'          => 'false',
            'goodlooking'   => 'false',
        };
    }

    elsif ( $param eq 'hpux' ) {

        $field_data = {
            'os'            => 'HP UX',
            'creator'       => 'HP',
            'notes'         => 'None',
            'free'          => 'false',
            'cool'          => 'false',
            'goodlooking'   => 'false',
        };
    }

    elsif ( $param eq 'linux' ) {

        $field_data = {
            'os'            => 'Linux',
            'creator'       => 'Linus Torvalds',
            'notes'         => 'World Domination 2002',
            'free'          => 'true',
            'cool'          => 'true',
            'goodlooking'   => 'true',
        };
    }

    elsif ( $param eq 'netware' ) {

        $field_data = {
            'os'            => 'Netware',
            'creator'       => 'Novell',
            'notes'         => 'Nice file/print server, slowly fading away..',
            'free'          => 'false',
            'cool'          => 'true',
            'goodlooking'   => 'false',
        };
    }

    elsif ( $param eq 'os2' ) {

        $field_data = {
            'os'            => 'OS/2 Warp',
            'creator'       => 'IBM',
            'notes'         => 'Wonder what companies would be using at work instead of NT if Microsoft had finished this one out.',
            'free'          => 'false',
            'cool'          => 'true',
            'goodlooking'   => 'false',
        };
    }
    elsif ( $param eq 'plan9' ) {

        $field_data = {
            'os'            => 'Plan 9',
            'creator'       => 'Bell Labs',
            'notes'         => 'Nice system, too bad the driver support never made it.',
            'free'          => 'true',
            'cool'          => 'true',
            'goodlooking'   => 'true',
        };
    }

    elsif ( $param eq 'solaris' ) {

        $field_data = {
            'os'            => 'Solaris',
            'creator'       => 'Sun Microsystems',
            'notes'         => 'Open Source Star Office - nice move',
            'free'          => 'false',
            'cool'          => 'true',
            'goodlooking'   => 'true',
        };
    }

    elsif ( $param eq 'windows' ) {

        $field_data = {
            'os'            => 'Windows',
            'creator'       => 'Microsoft',
            'notes'         => 'At least they got RAM prices down',
            'free'          => 'false',
            'cool'          => 'false',
            'goodlooking'   => 'false',
        };
    }

    # Change the name of the title, which is written in HTML
    my $html_data = { app_title => "OS Info: $field_data->{os}" };

    # Send the data we just defined to the browser, and focus the form element
    # named 'selectlist'
    return $self->param('OpenThought')->serialize({
                                            fields => $field_data,
                                            html   => $html_data,
                                            focus  => "selectlist",
                                         });
}

1;
