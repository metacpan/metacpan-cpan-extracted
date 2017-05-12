# This file is Copyright (c) 2000-2003 Eric Andreychek.  All rights reserved.
# For distribution terms, please see the included LICENSE file.
#
# $Id: Template.pm,v 1.23 2003/08/12 03:07:23 andreychek Exp $
#

package OpenThought::Template;

use strict;
use HTML::Template();

$OpenThought::Template::VERSION = sprintf("%d.%02d", q$Revision: 1.23 $ =~ /(\d+)\.(\d+)/);

# Template constructor
sub new {
    my ( $class, $op, $url ) = @_;

    my $self = {
        OP            => $op,   # OpenPlugin object
        url           => $url,  # URL where the find the HTML Content
        template_obj  => "",    # HTML::Template object
    };

    bless ($self, $class);

    return $self;
}

# Pulls the template off the disk
sub retrieve_template {

    my $self = shift;

    eval {
        $self->{template_obj} = HTML::Template->new(
            filename => "index-template.html",
            path     => [ "$OpenThought::Prefix/share/OpenThought/templates" ],
         );
    };
    if( $@ ) {
        $self->{OP}->exception->throw( "Error creating HTML Template ",
                                       "Object!: $@" );
    }
}

# Inserts generated parameters into the template
sub insert_parameters {
   my $self = shift;

   $self->{template_obj}->param( $self->gen_template_params );
}

# Uses the template module to display the template
sub return_template {
    my $self = shift;

    # Call the output method of the html::template object
    return $self->{template_obj}->output;
}

# Figures out the all the parameters for a particular template
sub gen_template_params {
    my $self = shift;
    my $OP   = $self->{OP};

    unless ( exists $OP->config->{'options'} ) {
        $OP->exception->throw("Can't find the 'options' section in the ",
                "config file!  Are you sure you registered the ",
                "OpenThought.conf config file?");
    }
    return {
      session_id          => $OP->session->create(),
      wrong_browser       => $self->_escape_javascript_text(
                             $OP->config->get('options', 'wrong_browser')),
      fetch_start         => $OP->config->get('options', 'fetch_start'),
      fetch_display       => $OP->config->get('options', 'fetch_display'),
      fetch_finish        => $OP->config->get('options', 'fetch_finish'),
      runmode_param       => $OP->config->get('options', 'runmode_param'),
      checked_true_value  => $OP->config->get('options', 'checked_true_value'),
      checked_false_value => $OP->config->get('options', 'checked_false_value'),
      application_url     => $self->{url},

      # These options requires a default
      max_selectbox_width =>
          $OP->config->get('options', 'max_selectbox_width') || "0",
      debug               => $OP->config->get('options', 'debug') || "0",
   };

}

# Don't allow any odd characters to jam up the javascript parsing
sub _escape_javascript_text {
    my ($self, $text) = @_;

    if ( $text ) {

        # Escape quotes
        $text =~ s/"/\"/g;

        # Okay, I don't understand how or why this works one bit, but what
        # we're doing is taking the text \n and changing it to \\n
        $text =~ s/\\n/\\n/g;
    }

    return $text;
}

1;
