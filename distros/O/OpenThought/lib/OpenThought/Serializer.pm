# This file is Copyright (c) 2000-2003 Eric Andreychek.  All rights reserved.
# For distribution terms, please see the included LICENSE file.
#
# $Id: Serializer.pm,v 1.33 2003/08/20 03:11:01 andreychek Exp $
#

package OpenThought::Serializer;

use strict;

$OpenThought::Serializer::VERSION = sprintf("%d.%02d", q$Revision: 1.33 $ =~ /(\d+)\.(\d+)/);

# Defines the names, types, and default order of all the possible options and
# settings for the serialize and settings functions
my $PARAMS  = {
        order    => [   "auto_clear",
                        "max_selectbox_width",
                        "runmode_param",
                        "fetch_start",
                        "fetch_display",
                        "fetch_finish",
                        "fields",
                        "html",
                        "javascript",
                        "url",
                        "focus",
                    ],
        fields              => { type => "option", },
        html                => { type => "option", },
        javascript          => { type => "option", },
        url                 => { type => "option", },
        focus               => { type => "option", },
        auto_clear          => { type => "setting", },
        max_selectbox_width => { type => "setting", },
        runmode_param       => { type => "setting", },
        fetch_start         => { type => "setting", },
        fetch_display       => { type => "setting", },
        fetch_finish        => { type => "setting", },
};

# Serializer Constructer
sub new {
    my ( $this, $params ) = @_;

    my $class = ref( $this ) || $this;

    my $self = $params;

    bless ( $self, $class );

    return $self;
}

# Parses parameters, sends them off to be serialized
sub params {
    my ( $self, $params ) = @_;
    my $OP = $self->{OP};

    foreach my $param ( keys %{ $params } ) {

        # Verify the parameter was not blank
        if( $params->{$param} eq "" ) {
            $OP->log->warn("Parameter [$param] is blank!");
            next;
        }

        # Make sure the parameter we were sent is valid
        if ( exists $PARAMS->{$param} ) {

            # If the parameter is an option..
            if( $PARAMS->{$param}{type} eq "option" ) {
                $self->$param( $params->{$param} );
            }

            # If the parameter is a setting..
            elsif( $PARAMS->{$param}{type} eq "setting" ) {
                $self->settings( $param, $params->{$param} );
            }

            # This is odd, the type of this parameter isn't valid
            else {
                $OP->log->warn("Parameter [$param] has no valid type!");
            }
        }

        # If the parameter is not valid, display an error
        else {
            $OP->log->warn("Parameter [$param] does not exist!");
        }
    }
}

# Display, in the proper order, the serialized options/settings
sub output {
    my $self = shift;

    my ( $save, $serialized_data, $restore );
    $save = $serialized_data = $restore = "";

    # Decide between the typical order, or a user defined one
    my $order = $self->{order} || $PARAMS->{order};

    # Loop through all the possible parameters, in order
    foreach my $param ( @{ $order } ) {

        # Only do something here if we were just given a value for this
        # parameter by the user
        if( exists $self->{params}{$param} ) {

            # Options get serialized before settings
            if( $PARAMS->{$param}{type} eq "option" ) {
                $serialized_data .= $self->{params}{$param};
            }

            elsif( $PARAMS->{$param}{type} eq "setting" ) {

                # Save/restore the current settings if it's only a temporary
                # setting
                if( $self->{save_settings} ) {
                    $save    .= $self->settings_save( $param );
                    $restore .= $self->settings_restore( $param );
                }

                # Serialize the setting itself
                $serialized_data .= $self->{params}{$param};
            }
        }
    }

    # Hands JavaScript code to the browser.  The browser processes the data
    # automatically as we hand it over -- as far as the browser is concerned,
    # it is simply loading a new page now (but in the hidden frame).
    return $self->add_tags( "${save}${serialized_data}${restore}" );

}

# The user has html they would like displayed in place of existing html
sub html {
    my ( $self, $data ) = @_;

    $data = as_javascript( $data );
    $data = "${data}parent.OpenThoughtUpdate(Packet, 'html');";

    $self->{params}{html} = $data;

}

# The user has data they would like displayed in form fields contained within
# the HTML in the browser.
sub fields {
    my ( $self, $data ) = @_;

    $data = as_javascript( $data );
    $data = "${data}parent.OpenThoughtUpdate(Packet);";

    $self->{params}{fields} = $data;

}

# Calls the FocusField function within the browser, which in turn takes the
# cursor and puts it into a particular field
sub focus {
    my ( $self, $field ) = @_;

    $self->{params}{focus} = "parent.FocusField('$field');";

}

# Send Javascript code to be interpreted by the browser.  This would often be
# used to call a user defined Javascript function.. an example application of
# this would be to use the dynapi Dynamic HTML API Library to create and
# manipulate DHTML objects from the server.
sub javascript {
    my ( $self, $javascript_code ) = @_;

    #$self->{params}{javascript} = "parent.frames[0].$javascript_code";
    $self->{params}{javascript} =
        "with (parent.contentFrame) { $javascript_code }";
}

# Load a new document in the content frame, but keep the base files
sub url {
    my ( $self, $url ) = @_;

    my $session_id = $self->{OP}->session->session_id();

    my $sep = '?';
    $sep = '&' unless index($url, '?') eq "-1";

    $url = "'${url}${sep}OpenThought=<OpenThought><settings><session_id>$session_id</session_id><event>ui</event></settings></OpenThought>'";

    my $javascript_code = "parent.ExpireCache();";
    $javascript_code   .= "parent.frames[0].document.location.href = $url;";

    $self->{params}{url} = $javascript_code;
}

# Alter settings with the existing OpenThought Application
sub settings {
    my ( $self, $setting, $value ) = @_;

    $self->{params}{$setting} = "parent.set_$setting('$value');";
}

# Save the current value of a setting
sub settings_save {
    my ( $self, $setting ) = @_;

    return "var $setting=parent.get_$setting();";
}

# Restore the previous value of a setting
sub settings_restore {
    my ( $self, $setting ) = @_;

    return "parent.set_$setting($setting);";
}

# Here we take a Perl hash and convert it into a JavaScript data structure.
# The other option is to give the browser an XML packet and let it deserialize
# it, but we save a good 50-100ms by doing it here.
sub as_javascript {
    my $data = shift;
    my $packet;

    $packet = "Packet = new Object;";

    # Loop through each HTML element that needs filled (see the fields()
    # function)
    while ( my( $key, $val ) = each %{ $data } ) {

        # In the case of a simple x=y assignment, do the following.  This is
        # used for text, password, textbox, and uniquely named checkboxes
        if( not ref $val) {
            $val = escape_javascript( $val );
            $val = "" unless defined ( $val );
            $packet .= qq{Packet["$key"]="$val";};
        }

        # In the case of a radio button, or several checkboxes with the same
        # name
        elsif ( not ref $val->[0] and ref $val eq "ARRAY" ) {

            # If we are sent something like:
            #   $field->{'selectbox_name'} = [ "" ];
            # That means we wish to clear the selectbox
            unless ( defined $val->[0] and $val->[0] ne "" ) {

                $packet .= qq{$key=new Array;};
                $packet .= qq{$key\[0\]="";};
                $packet .= qq{Packet["$key"]=$key;};
                next;
            }

            $val->[0] = escape_javascript( $val->[0] );
            $val->[1] = escape_javascript( $val->[1] );
            $val->[1] = "" unless defined ( $val->[1] );

            $packet .= qq{$key=new Array;};
            $packet .= qq{$key\[0\]="$val->[0]";};
            $packet .= qq{$key\[1\]="$val->[1]";};
            $packet .= qq{Packet["$key"]=$key;};
        }

        # This is done for select boxes
        else {
            $packet .= qq{$key=new Array;};
            my $i=0;
            foreach my $array ( @{ $val } ) {

                # If we are only sent text for the selectlist, and no value --
                # define the value as empty.  When it gets to the browser, the
                # value will be made the same as the text
                $array->[1] = "" unless defined( $array->[1]);
                $array->[0] = escape_javascript( $array->[0] );
                $array->[1] = escape_javascript( $array->[1] );
                $packet .= qq{$key\[$i\]=new Array("$array->[0]","$array->[1]");};
                $i++;
            }
            $packet .= qq{Packet["$key"]=$key;};
        }
    }

    return $packet;
}

# Deserialize the input we were sent from the browser
sub deserialize {
    my ( $self, $xml ) = @_;

    # Deserialize the packet we were sent
    return OpenThought::XML2Hash::xml2hash( $xml );
}

# Adds the appropriate script tags to JavaScript code
sub add_tags {
    my ( $self, $code ) = @_;

    return "<script>${code}</script>";
}

sub escape_javascript {
    my $code = shift;

    return unless defined $code;

    $code =~ s/\\/\\\\/g;
    $code =~ s/\n/\\n/g;
    $code =~ s/\r/\\r/g;
    $code =~ s/\t/\\t/g;
    $code =~ s/\"/\\"/g;

    return $code;
}

1;
