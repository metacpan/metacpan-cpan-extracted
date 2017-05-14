# This file is Copyright (c) 2000-2007 Eric Andreychek.  All rights reserved.
# For distribution terms, please see the included LICENSE file.

package OpenThought;

=head1 NAME

OpenThought - An AJAX transport and helper library, making AJAX-based page updates trivial

=head1 SYNOPSIS

 use OpenThought();
 use CGI();

 my $OT = OpenThought->new();
 my $q  = CGI->new;

 # First, put everything you wish to give to the browser into a hash
 my ($fields, $html, $image);
 $fields->{'myTextBox'}    = "Text Box Data";
 $fields->{'myCheckbox'}   = "true";
 $fields->{'myRadioBtn'}   = "RadioBtn2Value";
 $fields->{'mySelectList'} = [
                               [ "text1", "value1" ],
                               [ "text2", "value2" ],
                               [ "text3", "value3" ],
                             ];

 $html->{'id_tagname'} = "<b>New HTML Code</b>";

 $image->{'image_name'} = "http://example.com/my_image.gif";

 # You can also execute JavaScript, just put it into a scalar
 my $javascript_code = "alert('Howdy!')";

 # Then send it to the browser using:

 $OT->param( $fields );
 $OT->param( $html );
 $OT->param( $image );
 $OT->focus( "myTextBox" );
 $OT->javascript( $javascript_code );

 print $q->header:
 print $OT->response();

 # Or use the utility method:
 print $q->header;
 print $OT->response( param      => $fields,
                      param      => $html,
                      param      => $image,
                      focus      => "myTextBox",
                      javascript => $javascript_code,
                    );


 # In a seperate HTML file, you might have this (which is where you'd first
 # point the browser, the HTML then calls the Perl when you click the button or
 # select list)
 <html>
   <head>
     <script src="OpenThought.js"></script>
   </head>
   <body>
   <form name="my_form" onSubmit="return false">
     <input type="text" name="myTextBox">
     <input type="checkbox" name="myCheckbox">
     <input type="radio" name="myRadioBtn" value="RadioBtn1value">
     <input type="radio" name="myRadioBtn" value="RadioBtn2value">
     <select name="mySelectList" onChange="OpenThought.CallUrl(
                'http://example.com/my_openthought_app.pl', 'mySelectList')">
     <span id="id_tag_name">HTML Code will go here</span>

     // Sends the current value of the textbox 'myTextBox', as well as the
     // param 'this' with the value of 'that', to 'my_openthought_app.pl'.
     <input type="button" onClick="OpenThought.CallUrl(
                'http://example.com/my_openthought_app.pl', 'myTextBox', 'this=that')">
  </form>
  </body>
 </html>

=head1 DESCRIPTION

OpenThought is a library which implements an API for AJAX communication and
updates.  You can perform updates to form fields, HTML, call JavaScript
functions, and more with a trivial amount of code.  OpenThought strives to
provide a simple yet powerful and flexible means for creating AJAX
applications.

The interface is simple -- you just build a hash.  Hash keys are mapped to
field names or id tags in the HTML.  The value your hash keys contain is
dynamically inserted into the corresponding field (without reloading the page).

==head1 COMPATABILITY

OpenThought is compatible with a wide range of browsers, including Internet
Explorer 4+, Netscape 4+, Mozilla/Firefox, Safari, Opera, Konqeueror, and
others.  It detects the browsers capabilities; if the browser doesn't support
new functions such as XMLHttpRequest or XMLHTTP, it falls back to using
iframes.

=head1 METHODS

=cut

use strict;
use Carp;

$OpenThought::VERSION="1.99.16";

$OpenThought::DEBUG ||= 0;

use vars qw( $DEBUG );


#/-------------------------------------------------------------------------
# function: new
#

=pod

=over 4

=item new()

 $OT = OpenThought->new();

Creates a new OpenThought object.

=item Return Value

=over 4

=item $OT

OpenThought object.

=back

=back

=cut

# The main OpenThought constructor
sub new {
    my ( $pkg, $args ) = @_;

    $args ||= {};

    my $class = ref $pkg || $pkg;

    my $self = {

        %{ $args },

        _persist  => $args->{persist} || 0,

    };

    bless ($self, $class);

    $self->_init();

    return $self;
}

sub _init {
    my $self = shift;

    my @settings = qw(
                        log_enabled
                        log_level
                        require
                        channel_type
                        channel_visible
                        channel_url_replace
                        selectbox_max_width
                        selectbox_trim_string
                        selectbox_single_row_mode
                        selectbox_multi_row_mode
                        checkbox_true_value
                        checkbox_false_value
                        radio_null_selection_value
                        data_mode
                );

    delete $self->{_settings} if exists $self->{_settings};

    foreach my $setting ( @settings ) {
        $self->{_settings}{$setting} = [];
    }

    $self->{_response} = [];

}


# Generate, in the proper order, the serialized params and settings
sub output {
    my $self = shift;

    my ( $save, $serialized_data, $restore );
    $save = $serialized_data = $restore = "";

    my @settings;
    foreach my $setting ( keys %{ $self->{_settings} } ) {
        # There needs to be at least one passed in
        next unless scalar @{ $self->{_settings}{$setting} } > 0;

        $serialized_data .= join '', @{ $self->{_settings}{$setting} };
        push @settings, $setting;
    }

    # Grab all the response data (params, focus, url, javascript, etc)
    $serialized_data .= join '', @{ $self->{_response} };

    # Save/restore the current settings unless told to make them
    # persist
    unless( $self->{settings_persist} ) {
        if (@settings) {
            $save    .= $self->_settings_save( @settings );
            $restore .= $self->_settings_restore( @settings );
        }
    }

    # Hands JavaScript code to the browser.  The browser processes the data
    # automatically as we hand it over -- as far as the browser is concerned,
    # it is simply loading a new page now (but in the hidden frame).
    my $code = $self->_add_tags( "${save}${serialized_data}${restore}");

    $DEBUG && carp $code ;

    return $code;

}

*auto_param = \&param;
*fields     = \&param;
*html       = \&param;
*images     = \&param;

# The user has html, input fields, or images they want displayed in the browser
sub param {
    my ( $self, $data, $options ) = @_;

    if (ref $data eq "ARRAY") {
        $options = $data->[1] || {};
        $data    = $data->[0] || {};
    }

    $data = $self->_as_javascript( $data );

    my $save = "";
    my $restore = "";
    if ($options) {
        $save =    $self->_settings_save( keys %{ $options } ) .
                   $self->settings($options, 1);
        $restore = $self->_settings_restore( keys %{ $options } );
    }

    $data = "${save}parent.OpenThought.ServerResponse(${data});${restore}";

    push @{ $self->{_response} }, $data;

    return $self->_add_tags($data);
}

# Calls the Focus function within the browser, which in turn takes the
# cursor and puts it into a particular field
sub focus {
    my ( $self, $field ) = @_;

    my $data = " parent.OpenThought.Focus('$field');";

    push @{ $self->{_response} }, $data;

    return $self->_add_tags($data);
}

# Send Javascript code to be interpreted by the browser.  This would often be
# used to call a user defined Javascript function.. an example application of
# this would be to use the dynapi Dynamic HTML API Library to create and
# manipulate DHTML objects from the server.
sub javascript {
    my ( $self, $javascript_code ) = @_;

    # NOTE: it really doesn't work to escape the JS!  The developer needs to do
    # it themselves...
    my $data = " with (parent.document) { $javascript_code }";

    push @{ $self->{_response} }, $data;

    return $self->_add_tags($data);
}

# Jump to a new page with this url
sub url {
    my ( $self, $url ) = @_;

    unless ( $url ) {
        croak "You're missing the parameter to 'url'.";
    }

    my $javascript_code;

    if ( ref $url eq "ARRAY" ) {
        if ( $url->[0] ) {
            unless ( not ref $url->[0] ) {
                croak "The first element of the arrayref passed into 'url' should be a scalar containing the url.";
            }

            $javascript_code = "parent.OpenThought.FetchHtml('$url->[0]'";
        }
        if ( $url->[1] ) {
            unless ( ref $url->[1] eq "HASH" ) {
                croak "The second element of the arrayref passed into 'url' is optional, but if supplied, must be a hashref.";
            }
            foreach my $param ( keys %{ $url->[1] } ) {
                if ( defined $url->[1]->{ $param } ) {
                    $javascript_code .= ",'$param=$url->[1]{ $param }'";
                }
                else {
                    $javascript_code .= ",'$param'";
                }
            }
        }
    }
    elsif ( not ref $url ) {
        $javascript_code = "parent.OpenThought.FetchHtml('$url'";
    }
    else {
        croak "The 'url' method takes either a scalar containing the url, or an an arrayref containing both the url and a hashref with url parameters.";
    }

    $javascript_code .= ");";

    push @{ $self->{_response} }, $javascript_code;

    return $self->_add_tags($javascript_code);
}

# Alter settings within the existing OpenThought Application
sub settings {
    my ( $self, $settings, $return_only ) = @_;

    unless ( ref $settings eq "HASH" ){
        croak "When you pass in settings, they need to be a hash " .
             'reference.  Either $OT->settings( \%settings ) or ' .
             '$OT->response( settings => \%settings ).';
    }

    my $data;
    foreach my $name ( keys %{ $settings } ) {
        # Persist is special as well.  It defines whether the settings
        # being sent are to remain for the life of this page, or just for this
        # current request.
        if( $name eq "settings_persist" ) {
            $self->{settings_persist} = $settings->{$name};
        }

        # All other parameters are treated the same here
        elsif ( $self->{_settings}{$name} ) {
            my $setting = "parent.OpenThought.config.$name = \"" .
#                          $self->_escape_javascript( $settings->{$name} ) .  "\");";
                          $self->_escape_javascript( $settings->{$name} ) .  "\";";

            unless ($return_only) {
                push @{ $self->{_settings}{$name} }, $setting;
            }

            $data .= $setting;

        }
        else {
            carp "No such setting [$name].";
        }
    }

    if ($return_only) {
        return $data;
    }
    else {
        return $self->_add_tags($data);
    }
}


=pod

=over 4

=item param()

 $OT->param( \%data, [ \%settings ] );

Update input-type form field elements (text boxes, radio buttons, checkboxes,
select lists, text areas, etc), HTML elements, as well as images an image attributes.

This method accepts a hash reference containing keys which map to field
names, html id's, and image names.

The form element, html id, or image will be dynamically updated to contain the value found within the
hash key.

B<Text, Textarea, Password fields>: These are very straight forward.  The hash
values are inserted directly into the input fields matching the hash keys.

B<Radio buttons>: The value for the hash key should match the C<value>
attribute of the radio button element in your HTML code.  When the hash key and
value matches the radio button name and value, that radio button will become
checked.

B<Select Lists>: Sending a single array reference to a select list will cause
that data to be appended to the select list.  In contrast, sending data as a
reference to an array of arrays or an array of hashes will cause any values
within the select list to be overwritten with the new data.

You can modify this select list behaviour by using the
C<selectbox_single_row_mode> and C<selectbox_multi_row_mode> options.

When sending data to a select list (which, as we said, is done as an array),
the first element of the array is the text to be displayed, the second element
is the underlying value associated with that text.

Sending a single scalar value to a select list highlights the corresponding
entry in the select list which contains that value.

Sending undef, or a reference to an array with an empty string as it's only
element will cause the select list to be cleared.

B<HTML elements>: It accepts a hash reference containing keys which map to HTML id attributes.
You can add id tags for nearly any HTML attribute.  The hash values are inserted
within the html containing an id tag matching the hash key (using innerHtml).  The data may contain HTML
tags, which will be correctly displayed.

 $OT->param({ "html_id_tag" => "<b>foo</b>" }).

B<Images>: To change an image or image property, the hash key should be the image name.  If you just want
to load a new image, the hash value should be a scalar containing the url of the new image.

 $OT->param({ foo => 'http://example.com/new_image.jpg' });

 $OT->param({ foo => { width  => 100,
                       height => 150, });

B<Optional Parameter: Settings>: The second optional parameter is a hash reference of settings that will
effect just the data passed into this call of C<param()>.  See the C<settings()> method for a list of
available options.

=item javascript()

 $OT->javascript( "alert('Howdy');" );

This allows you to run JavaScript code, along with accessing JavaScript
functions and variables.

It accepts a string containing the JavaScript code you wish to execute.  There
is no need to add script tags, they will be added for you.

=item focus()

 $OT->focus( "field_name" );

This allows you to focus a given input field or anchor tag.

It accepts a string containing the name of the field or anchor tag you wish to
focus.  If it's a field, it will be given the cursor.  If it's an anchor tag,
the browser will jump to it's position on the page.

=item url()

 $OT->url( "http://example.com/my_openthought_app.pl" );

 $OT->url([ "http://example.com/my_openthought_app.pl" =>
               { example_param => some_value,
                 param2        => another_value } ]);

The C<url> method loads new page.

This method can be used by passing in the url as a scalar, or by passing in the
url and url parameters within an arrayref.  If you pass in an arrayref, the
first element of the array should be the url, the second element should be a
hash reference whose keys and values will be passed on as parameters to the new
url.

=item settings

 $OT->settings({
                        settings_persist           => boolean,
                        log_start                  => string,
                        log_level                  => string,
                        require                    => { ... },
                        http_request_type          => string,
                        channel_type               => string,
                        channel_visible            => boolean,
                        channel_url_replace        => boolean,
                        selectbox_max_width        => size,
                        selectbox_trim_string      => string,
                        selectbox_single_row_mode  => string,
                        selectbox_multi_row_mode   => string,
                        checkbox_true_value        => string,
                        checkbox_false_value       => string,
                        radio_null_selection_value => string,
                        data_mode                  => string,
                     });

Alter settings in the OpenThought application running in the browser.  Each
parameter is optional.  Only pass in the option(s) you wish to change.

For additional information on configuration, and for how/where to set the
defaults, please see the section labeled C<CONFIGURATION>.

This method accepts a hash reference where the keys are names of OpenThought
options, and the values are the new option values.

By default, these options will only be good for one request.  You can change
that behaviour by either passing in the C<persist> option to this method.

You can set the defaults for most of these settings at the top of the
OpenThought.js file.

=over 4

=item Parameters

=over 4

=item settings_persist()

 $OT->settings({ settings_persist => "true" });

This specifies whether or not the settings being changed in the browser should
be just for this request, or whether they should persist as long as the current
page is loaded.

The default is to not persist.

If you use this parameter, only items you specify will be executed.  That is,
if you fail to mention where C<fields> should be in the order, then C<fields>
will be completely ignored for that request.

If C<url> is not last, everything sent after it will be lost when the page
changes.

=item log_enabled

 $OT->settings({ log_enabled => "true" });

Enable a log window so you can see what's going on behind the scenes.  If
something in your app isn't working, try enabling this.  This can be very
useful for debugging, but you probably want it disabled while your app is in
production.  This, of course, won't work if your popup blocking software
doesn't allow popups from the site you're running your application from.

=item log_level

 $OT->settings({ log_level => "info" });

What log level to run at.  You have the ability to enable lots of debugging
output, only serious errors, and various levels in between.

Options are C<debug>, C<info>, C<warn>, C<error>, C<fatal>

=item require

 $OT->settings({ require =>
                        { "40dom" => "http://example.com/no_40dom",
                          "xmlhttp" => "http://example.com/no_xmlhttp",
                        } })

Define a set of browser requirements, and a page to go to if that requirement
is not met.

Available requirements are C<40dom>, C<xmlhttp>, C<layer>, C<iframe>,
C<htmlrewrite>.

=item http_request_type (EXPERIMENTAL)

 $OT->settings({ http_request_type => "POST" });

The request type for communications with the server.  This can be
overridden at any time by passing in either GET or POST as the first
parameter to CallUrl().  The default (and known to work) option is GET.

Using POST has only been minimally tested.  There have been problems noted when
using Firefox and POST, if the C<channel_type> option was changed from C<auto>
to C<iframes>.  This appears to be a Firefox bug.

Options are C<GET> or C<POST> (case sensitive).

=item channel_type

 $OT->settings({ channel_type => "iframe" });

The type of channel to use for communicating with the browser.

By default, OpenThought will attempt to use the XMLHttpRequest or XMLHTTP
functions available in recent browsers, then fall back to iframes if the
browser doesn't support those newer options.

However, XMLHttpRequest and XMLHTTP have one limitation -- for any given
request, the server can only respond once, and the response is all at the same
time.

Iframes don't have that restriction, and the server can send a variety of
responses throughout the duration of the request.

XMLHttpRequest/XMLHTTP are fine for most uses, but some applications may
benefit from being able to have the browser receive data a number of times
throughtout a single request (ie, irc and other realtime chat applications).

Options are C<auto> or C<iframe>.

=item channel_visible

 $OT->settings({ channel_visible => "true" });

Normally, the channel used to communicate with the server is invisible.  The
curious may wish to see whats going on inside it (or perhaps need it for
debugging).  Enabling the following will make the channel visible.  This only
works if the channel is an iframe (which means it's either an older browser, or
that you have C<channel_type> set to C<iframe>.

=item url_replace

 $OT->settings({ url_replace => "true" });

When using iframes and layers, the typical way to submit ajax requests to the
server involves using a 'document.location.replace()'.  This means the requests
aren't being stored in the browser history.  So, the back button will take you
to the previous *page*, not the previous AJAX request.  This is often what
people want.  This sometimes isn't what people want :-) Set to 'true' to not
add AJAX requests to the browser's history, set to 'false' to have them added
to the history.

This option has no effect when using XMLHttpRequest/XMLHTTP.

Options are C<true> or C<false>.

=item url_prefix

 $OT->settings({ url_prefix => "include/" });

During any call to the server (via CallUrl and FetchHtml), assume the script is
located in this directory (ie, the file/dir you pass in is relative to this
path).  If there's no trailing slash, it will add one.  This config option can
be overridden by beginning the url with 'http' or '/'.

=item selectbox_single_row_mode

 $OT->settings({ selectbox_single_row_mode => "append" });

This defines whether or not sending a new row (an arrayref) to the select list
overwrites the existing values, or adds to it.  It can be set to C<append> or
C<overwrite>.

The default behaviour for adding a row to select lists is to append itself to
the end of the selectlist.  Setting C<selectbox_single_row_mode> to C<overwrite>
value is how you can alter that behavior.  If C<selectbox_single_row_mode> is
C<overwrite>, the contents of a select list are overwritten by the new row.

When C<selectbox_single_row_mode> is set to C<append>, you can still clear a
select list by passing in an empty string as a parameter to the select list.

=item selectbox_multi_row_mode

 $OT->settings({ selectbox_single_row_mode => "overwrite" });

This defines whether or not sending multiple rows (an array of arrays) to the
select list overwrites the existing values, or adds to it.  It can be set to
C<append> or C<overwrite>.

The default behaviour for adding multiple rows to select lists is to overwrite
the existing list.  Setting C<selectbox_multi_row_mode> to C<append> value
is how you can alter that behavior.  If C<selectbox_multi_row_mode> is
C<append>, the contents of a select list are preserved, and all new data is
appended to the end of the select list.

When C<selectbox_multi_row_mode> is set to C<append>, you can still clear a
select list by passing in an empty string as a parameter to the select list.

=item selectbox_max_width

 $OT->settings({ selectbox_max_width => "50" });

Limit how many characters an entry in a select box can contain, 0 to not
constrain the size.  The default is 30.

Upon dynamically receiving select box content, most browsers resize the select
box to the width of the longest entry.  This seems like a neat feature, but
resizing the select box will often adversely affect other parts of your visual
layout.   This option allows you to modify the size of text going into a select
box, so the browser doesn't make the select box too big.

Netscape 4 is the only browser known not to perform dynamic resizing.  Instead,
it allows you to scroll side to side to view long text.

See C<selectbox_trim_string> to learn what the trimmed text is replaced with.

=item selectbox_trim_string

 $OT->settings({ selectbox_trim_string => "+" });

Text to add to strings trimmed because of C<selectbox_max_width>.

If the text being inserted into a selectbox needs to be resized to fit (due to
C<selectbox_max_width>), replace the removed text with the following string to
make it clear that the string was trimmed.

The default is to use two periods: ..

=item checkbox_true_value

 $OT->settings({ checkbox_true_value => "1" });

The value a checkbox will return if it is checked, and no value is assigned to
the checkbox (via the value= attribute).  The default is "1".

=item checkbox_false_value

 $OT->settings({ checkbox_false_value => "0" });

The value a checkbox will return if it isn't checked.

=item radio_null_selection_value

 $OT->settings({ radio_null_selection_value => "0" });

The value a group of radio buttons will return if none of them are selected.
The default is "0".

=item data_mode

 $OT->settings({ data_mode => "append" });
 $OT->param( $fields => { data_mode => "append" } );

Define whether data should be overwritten or appended, for objects other than
select lists.  It can be set to C<append> or C<overwrite>.

By default, data sent from the server to the browser overwrites existing
content.  This allows you to change that behaviour, and have it append.

=back

=back

=item response

 print $OT->response();

This returns the data gathered thus far, in a manner in which the browser will
understand (ie, JavaScript).  Typically, you would just send this directly to
the browser, though you can modify it first if you desire.

Calling C<response> clears all the data gathered so far on the internal stack.

=cut

*parse_and_output = \&response;

sub response() {
    my $self = shift;

    if ( length(@_) and ref $_[0] eq "HASH" ) {
        my $params = $_[0];

        foreach my $param ( keys %{ $params } ) {
            $self->$param( $params->{$param} );
        }
    }
    else {
        my @params = @_;

        #for my $i ( 1 .. (length @params) / 2) {
        while ( scalar @params > 0 ) {

            my $method        = shift @params;
            my $method_params = shift @params;

            $self->$method( $method_params ) if $method ne "";
        }
    }

    return $self->output();
}

# Save the current value of a setting
sub _settings_save {
    my ( $self, @settings ) = @_;

    my $data;

    foreach my $setting ( @settings ) {
        $data .= " var __$setting=parent.OpenThought.config.$setting;";
    }

    return $data;
}

# Restore the previous value of a setting
sub _settings_restore {
    my ( $self, @settings ) = @_;

    my $data;

    foreach my $setting ( @settings ) {
        $data .= " parent.OpenThought.config.$setting = __$setting;";
    }

    return $data;
}

# Convert a Perl hash into a JavaScript data structure.  This has all been
# recently (7/24/05) modified to use JSON notation:
#   http://www.crockford.com/JSON/index.html
sub _as_javascript {
    my ($self, $data) = @_;
    my $packet;

    unless ( ref $data eq "HASH" ) {
        croak "Data sent to the serializer function must be a reference to a hash.";
    }

    $packet = "{";

    # Loop through each element that needs filled
    while ( my( $key, $val ) = each %{ $data } ) {

        # In the case of a simple key=value assignment, do the following.  This
        # is used for text, password, textbox, uniquely named checkboxes, and
        # radio buttons
        # Convert: $hash->{key} = "value"
        # To:      key : value,
        if( not ref $val) {
            if ( defined $val ) {
                $val = $self->_escape_javascript( $val );
                $packet .= qq("$key": "$val",);
            }
            else {
                $packet .= qq("$key": null,);
            }
        }

        # In the case of adding one item to a select box, or clearing a select box
        # Convert: $hash->{key} = [ $val1, $val2 ]
        # To:      key: [ val1, val2 ],
        elsif ( ref $val eq "ARRAY" and not ref $val->[0] ) {

            # If we are sent something like:
            #   $field->{'selectbox_name'} = [ "" ];
            # That means we wish to clear the selectbox
            unless ( defined $val->[0] and $val->[0] ne "" ) {

                $packet .= qq("$key": [ "" ],);
                next;
            }

            $packet .= qq("$key": [ );
            $packet .= join '',
                map { '"' . ($self->_escape_javascript($_) || "") . '",'}
                @{ $val };

            chop $packet;
            $packet .= qq( ],);
        }

        # For updating select lists using an array of hashes
        # Convert: $hash->{key} = [ { val1 => val2 }, { val3 => val4 } ]
        # To:      key: [ { val1: val2 }, { val3: val4 } ],
        elsif ( ref $val eq "ARRAY" and ref $val->[0] eq "HASH" ) {
            $packet .= qq("$key": [ );

            foreach my $hash ( @{ $val } ) {
                while ( my ( $key1, $val1 ) = each %{ $hash } ) {
                    $val1 = $self->_escape_javascript( $val1 );
                    $packet .= qq({"$key1": "$val1"},)
                }
                chop $packet;
            }
            $packet .= qq( ],);
        }

        # This is done for adding multiple items to select boxes
        # Convert: $hash->{key} = [ [ val1, val2 ], [ val3, val4 ] ]
        # To:      key: [ [ val1, val2 ], [ val3, val4 ] ],
        elsif ( ref $val eq "ARRAY" and ref $val->[0] eq "ARRAY" ) {
            $packet .= qq("$key": [ );
            my $i=0;
            foreach my $array ( @{ $val } ) {

                # If we are only sent text for the selectlist, and no value --
                # define the value as empty.  When it gets to the browser, the
                # value will be made the same as the text
                $array->[1] = "" unless defined($array->[1]);

                $array->[0] = $self->_escape_javascript( $array->[0] );
                $array->[1] = $self->_escape_javascript( $array->[1] );
                $packet .= qq(["$array->[0]","$array->[1]"],);
                $i++;
            }
            chop $packet;
            $packet .= qq( ],);
        }

        # This updates multiple checkboxes with the same name
        # Convert: $hash->{key} = { key1 => val1, key2 = val2 }
        # To:      key : { key1 : val1, key2 : val2 },
        elsif ( ref $val eq "HASH" ) {
            $packet .= qq("$key": { );
            foreach my $key2 ( keys %{ $val } ) {
                $val->{$key2} = "" unless defined($val->{$key2});
                $val->{$key2} = $self->_escape_javascript( $val->{$key2} );
                $packet .= qq("$key2": "$val->{$key2}",);
            }
            chop $packet;
            $packet .= qq(},);
        }
        else {
            carp "I'm not sure what to do with the data structure you sent!";
        }
    }
    chop $packet;
    $packet .= "}";

    return $packet;
}

# Adds the appropriate script tags to JavaScript code
sub _add_tags {
    my ( $self, $code ) = @_;

    # The <OT> tag is a bit of a unique ID... so that the JS can detect the
    # difference between OT adding the tags, and tags added by the developer.
    # The JS will strip all these tags -- everything but $code -- if the call
    # is done through XmlHttpRequest or similar, but they're required with
    # iframes.
    #
    # We're doing this instead of passing parameters from the browser to the
    # server and testing on them to see if the tags should be added at all.
    # Basically, this prevents the developer from having to pass params into OT
    # that they don't understand, which I think makes things more complicated
    # than they need to be.  You have my email address, feel free to argue :-)
    return qq{\r <OT><body onLoad="parent.OpenThought.ResponseComplete(self)"></body><script>${code}</script><OT> \r};
}

sub _escape_javascript {
    my ( $self, $code ) = @_;

    return unless defined $code;

    $code =~ s/\\/\\\\/g;
    $code =~ s/\n/\\n/g;
    $code =~ s/\r/\\r/g;
    $code =~ s/\t/\\t/g;
    $code =~ s/\"/\\"/g;
    $code =~ s/([\x00-\x1F])/sprintf("\\%03o", ord($1))/ge;

    return $code;
}

1;

__END__

=head1 JAVASCRIPT FUNCTIONS

There are a number of JavaScript functions available after you've added the
following to your HTML:

  <script src="OpenThought.js"></script>

=item CallUrl

 OpenThought.CallUrl('script.pl', [ 'element1', 'element2', 'name1=value2' ] )

Make an AJAX call (ie, in the background) to the server, and dynamically update the
current page with the server's response.

=over 4

=item Parameters

=over 4

=item Parameter #1: url

The first parameter is the url to send the request to.  Due to limitations with
JavaScript, the location being called must be on the same server the HTML page
which is currently loaded came from.

=item Optional Parameters

After the url, all other parameters are optional.  You can have as many
additional parameters as you like.  Additional parameters would be one of the
following:

=over 4

=item elements

Passing in an element name sends the current value of that element to the server.

An element could be the name of a form field (ie, text box, select list,
checkbox), the name of an image, an id tag of an html element, and so on.

B<wildcards>

If you have a bunch of elements that all start or end with the same string, and
you don't want to pass in each one individually, you can add an asterisk '*'
for as a wildcard.  For example, sending in '*name' would send in values for
the elements named first_name, last_name, and spouse_name.  Sending in just '*'
with nothing else will pass in every form element on the page as a parameter.

=item expressions

If you have a static value that you'd like to send in, instead of an element,
you may do so using the syntax:

 'param_name=param_value'

=back

B<arrays>

You may find it works out easier for you to send in an array, instead of
several individual parameters.  That's fine, you may send in one or more arrays
instead of single scalar values.

B<method>

You can optionally specify the HTTP Request method to use.  If you wish to do
that, you may put C<GET> or <POST> as the first parameter (before the url).  If
not specified, it uses whatever is in the C<http_request_method>, which
defaults to "GET".

=back

=back

=item FetchHtml

 OpenThought.FetchHtml('script.pl', [ 'element1', 'element2', 'name1=value2' ] )

This function is called just like C<CallUrl()>, but they do very different
things.  Unlike C<CallUrl()>, C<FetchHtml>'s job is to load a new page.

Other than that, since it's usage is identical to C<CallUrl()>, see the
C<CallUrl> parameters above for information on how to use it.

=head1 JAVASCRIPT UTILITY FUNCTIONS

=item GetElement

 [element_type, element_value] = OpenThought.GetElement("someName");

Retrieves the current type and value for an element.

For example, if the element is a text box, this will be the text that currently
resides within the text box.  If it's a select list, it'll be the active
selection(s).

=item SetElement

 OpenThought.SetElement("elementName", "new_value");

Sets the element with name "elementName" to the desired value.

=item FindElement

 element_object = OpenThought.FindElement("elementName");

Returns the object for C<elementName>.

This is basically a cross browser implementation of C<getElementById>.  It works
in all browsers that can run OpenThought.

=item Focus

Focus a form field or jump to an anchor tag.

=item HideElement, ShowElement

Hide and Show elements.

This allows you to hide pieces of HTML until some action occurs.  On any event,
you may call either of these to show or hide any type of HTML, including form
elements and even entire div tags.

=item DisableElement, EnableElement

 OpenThought.EnableElement( "element_or_form_name" );

 OpenThought.DisableElement( form_name, { "EXCEPT" : [ "element3", "element4"] } );

Enable or disable an element or form.

There are cases where you'd want to disable an element or entire form.  For
example, if you want to display an HTML based dialog box, and disable all input
except for the newly displayed dialog.

Calling C<DisableElement()> causes the elements (generally form elements) in question
to be greyed out, and to no longer accept input.  Using C<EnableElement>
re-enables the input. You can pass in '*' as the parameter to enable or disable
all form elements.

Note that disabled form elements cannot submit data to the server, you must
first enable them.

If you choose to pass in a form name or '*' (as opposed to an individual
element name), it will loop over all the elements in the form or forms, and
disable them individually.  Since you may not wish for each element to become
disabled, you can pass in an exception list as the last parameter.  To do so,
you can use JavaScripts ability to create anonymous hashes.  The first
parameter to the hash must be "EXCEPT", the second parameter is an array,
containing the names of all the elements to skip over.  In the above example,
C<element3> and <element4> are going to be skipped.

=item ElementChanged

 bool = OpenThought.ElementChanged("myElement")

Determine if a given element has changed since it's been loaded in the browser.

After passing in a form element name, it will return true or false, depending
on whether or not the value of that particular form element has been changed
since the page was initially loaded.

It cannot tell the difference between the user changing a value, and JavaScript
changing the value.  So, if you were to code something which altered the value
of an element, it would always return C<true> that it has been modified.

=item ElementReset

 OpenThought.ElementReset('ElementName')

Resets an element to it's original state.

This is quite similar to what a C<reset> button in a form does, but it works
for individual elements.

=item log

 OpenThought.log.debug("Output some debugging info");
 OpenThought.log.error("Something terrible has happened");

Log information, based on the current log level.

Available log levels are C<debug>, C<info>, C<warn>, C<error>, and C<fatal>.  If
the current level is set to C<warn>, only calling the C<warn>, C<error>, and
C<fatal> methods would generate logging output.  The C<debug> and C<info>
methods would be ignored.  To get more logging, you'd simply have to set
C<log_level> to C<info> or C<warn>.

The default log level is set in the configuration section, and may be changed
programmatically on the fly.  And of course, the log.enabled setting must be
true for you to actually see any of these messages.

=item browser

 OpenThought.browser.version
 OpenThought.browser.w3c

=item config

 alert( OpenThought.config.log_level );
 OpenThought.config.log_enabled = true;

Access any of the configuration settings.

You may change any of these on the fly.

=head1 CONFIGURATION

Most of the configuration defaults are kept at the top of the OpenThought.js
file.  All of those defaults can be changed at runtime using the C<settings>
method, discussed above.

While you can modify them directly in that file, that would mean future
installations of OpenThought could cause them to be overwritten.

After loading those settings, the OpenThought JavaScript looks for the
existance of a function (class) named C<OpenThoughtConfigLocal>.  If it exists,
it uses variables setup in it to override what's at the top of the
OpenThought.js.

To take advantage of that, you could create a (arbitrarily named) file called
OpenThoughtLocal.js, and insert the following:

 function OpenThoughtConfigLocal() {

     ////////////////////////////////////////////////
     //
     // Local Config section - Custom config options
     //

     this.log_enabled = true;
     this.log_level = "debug";

     this.channel_visible = true
     this.selectbox_max_width = "50"

 }

The above would enable logging at the debug level, make the communication
channel visible (for iframes anyway), and make the max selectbox width 50
characters instead of 30.

Then, in your HTML code, you'd simply add this line:

 <script src="OpenThoughtLocal.js"></script>

That must be B<above> the line you use to include the OpenThought.js file.
So, the two lines together would look like:

 <script src="OpenThoughtLocal.js"></script>
 <script src="OpenThought.js"></script>

=head1 SENDING DATA TO THE BROWSER

The following methods show you how you can send data from the server to the
browser.

B<Just a Hashref>

You only need a reference to a hash to send data to the browser.  If the
hashref containing all of our data is called %data, then all we need to
do in our code is:

 # Populate the input fields, html, and/or images with the data within our hashref
 print $OT->param( \%data );

The keys in the $data hash would map to input field names, HTML id tags, or
image names in the browser.

B<Populating Text, Password, and Textarea Form Elements>

 $data->{'fieldname'} = "data";

B<Populating and Selecting Select List Form Elements>

 $data->{'selectbox_name'} = [
                                 [ "Example 1", "value_one"   ],
                                 [ "Example 2", "value_two"   ],
                                 [ "Example 3", "value_three" ],
                             ];

This will set the text of a select box to the left column above, and the
underlying value of that text to the right column.

You can also use an array of hashes:

 $data->{'selectbox_name'} = [
                                 { "Example 1" => "value_one"   },
                                 { "Example 2" => "value_two"   },
                                 { "Example 3" => "value_three" },
                             ];
In the case that you don't have two columns worth of data you wish to use, you
can also do:

 $data->{'selectbox_name'} = [
                                 [ "Example 1"  ],
                                 [ "Example 2"  ],
                                 [ "Example 3"  ],
                             ];

This makes both the text and value of the selectbox identical, and requires
sending less data to the browser (which, of course, saves bandwidth, woohoo!).

By default, the above array of arrays and array of hashes will erase the
current contents of the select list with the data in the array.  To append a
single item to the end of the select list, you can use the following:

 $data->{'selectbox_name'} = [ "Example 1", "value_one" ];

You can also use:

 $data->{'selectbox_name'} = [ "Example 1" ];

The latter will set both the text and value of the entry to "Example 1".

Also, you can use the following methods to manually clear the contents of a
select list:

 $data->{'selectbox_name'} = undef;

   -- or --

 $data->{'selectbox_name'} = [ "" ];

That can be particularly useful if c<selectbox_single_row_mode> or
selectbox_multi_row_mode are set to append, but you need to clear out the list
for new data.

To select (highlight) an item in an existing select list, you can send a
single string to your select list like so:

 $data->{'selectbox_name'} = "optionvalue";

Which ever item in the select list has the value C<optionvalue> will become
highlighted.

B<Selecting Checkbox Elements>

 $data->{'checkbox_name'} = "boolean";

To uncheck a checkbox, set value to C<false>, which can be any of:

=over 4

=over 4

=item * false | False | FALSE

=item * unchecked

=item * any number less then 1

=item * The current value of C<checked_false_value>

=back

=back

Setting the value to anything other then the above will be interpreted as
C<true>, and will cause the checkbox to be checked.

Additionally, setting c<checked_true_value> to any of the above "normally false"
values will override them.

B<Selecting Radio Button Form Elements>

 $data->{'radiobtn_name'} = "radiobtn_value";

radiobtn_value is the value in the "value=" tag of the radio button.

Radio buttons can only be selected, they cannot be directly unselected.  The
only way to unselect a radio button is to select a different radio button in
that group.

B<Updating Existing HTML Code>

 $data->{'id_tagname'} = "<h2>New HTML Code</h2>";

This inserts the code "<h2>New HTML Code</h2>" inside the tag with the id
attribute labeled 'id_tagname'.  This replaces any text or code that may have
originally existed within that tag.

Updating HTML does not work in Netscape 4.x, as it has a rather odd DOM.  It is
capable of working if someone felt like coding it, let me know if you're
interested :-)

B<Focusing an Element>

You can give the focus to any form element or anchor tag within the browser
simply by saying:

 $OT->focus("fieldname");

B<Running JavaScript>

You can easily send JavaScript to the browser, allowing you to call JavaScript
functions, access JavaScript variables, and even create new functions -- all
from the server.

The following calls the JavaScript 'alert' function:

 $OT->javascript("alert('Hello!')");

The next example calls the hypothetical javascript function 'myfunction', using
C<param1> and C<param2> as arguments to that function:

 $OT->javascript("myfunction(param1, param2);");

You can send any JavaScript you want, but make sure it's properly formated
code.  OpenThought does not validate whether or not your JavaScript syntax is
correct, the browser will be your judge!  If something isn't working, pull up
your browser's JavaScript console, it may provide you with some insight as to
what isn't working properly.  Setting C<log_enabled> to C<true> may help as
well. You do not need to include script tags.

B<Loading a New Page>

There are plenty of cases where it may be desirable load a new page within your
content frame.  Loading a new page is quite simple, and can be initiated from
the server, or from the browser.

Here is an example of how you might tell the browser, from the server, to load
a new page:

 $OT->url('http://example.com/newurl.pl');

This function will have the browser call the perl script 'newurl.pl'.  It's
then up to newurl.pl to deliver some sort of content back to the browser.

B<Using DBI>

You can send the results of a database query directly to the browser, and have
the data from the results put into their respective fields.  You only need one
thing in order for this to work -- the field names in your database need
to match your field names in the HTML.  For example:

 my $sql = "SELECT name, address, phone, age, married " .
           "FROM sometable WHERE name="Tim Toady";

 my $sth = $dbh->prepare($sql);
 $sth->execute;

 $data = $sth->fetchrow_hashref;

 $OT->param($data);
 print $q->header();
 print $OT->response();

In this case, lets say we have 'name', 'address', 'phone', and 'age' as
names of text fields in our HTML, and 'married' is a checkbox.  As soon as we
send $data to the browser, these fields (which must exist) will all be filled
in with the appropriate data.

This also works for select lists:

 my $sql = "SELECT name, ssn FROM sometable";

 my $sth = $dbh->prepare($sql);
 $sth->execute;

 $data->{'people'} = $sth->fetchall_arrayref;

 print $OT->parse_and_output({ auto_param => $data });

This selects the name and social security number from everyone in the table,
and will allow us to use it to populate a select list named 'people'.  The
names are what will be displayed, the ssn will become the corresponding value.

=head2 Sending Data to the Server

You can send data from the browser to the server anytime an event occurs.
Events are often generated by clicking buttons or links.  JavaScript functions
like onMouseOver, onClick, onChange, etc.. they all allow you to cash in on
an event, and you can take advantage of them to send data to the server at that
time.

There are two JavaScript functions available to you for communicating with the
server.  Their usage and parameters are identical, but they perform very
different functions.

=over 4

=item CallUrl

The C<CallUrl> function is used when you want to use "AJAX" or "Remote
Scripting" -- calling the browser in the background, and dynamically update the
page with it's response.

=item FetchHtml

The function C<FetchHtml> is what you want to use when you B<do> want to load a
new page.

=back

The following are some examples of how you might use these two functions.  In
any of the following situations, the two functions are interchangable.  It all
just depends on what you want to happen.

B<Button Events>

 <input type="button" name="search" value="Click me!"
        onClick="OpenThought.CallUrl('servercode.pl',
                                     'field1', 'field2', 'foo=bar');

Upon clicking this button, it will send the current contents of the fields
named 'field1' and 'field2' to servercode.pl.  It will also send
the expression "foo=bar".  When this gets to the server, 'foo' will be a
parameter name, 'bar' will be it's value.

Be careful using submit and image buttons.  You don't want your form to
actually perform a "submit", which causes the page to refresh.  You are merely
looking to "catch" the submit event, and perform an action when that submit
even is generated.  If you wish to use a submit or image button, you should
define your form like this:

 <form name="myForm" onSubmit="return false">

Now your browser can use submit and image buttons to send data to the server
without actually refreshing.

B<Using 'A' Links>

The following example shows you how you can use a typical HTML link to send
data to the server without causing the page to refresh:

 <a href="#" onClick="OpenThought.CallUrl('/OpenThought/servercode.pl',
                                          'run_mode=forgot_password');
                                           return false;">
                                           Click me!</a>

Note: For things to work properly when using links, your JavaScript call has to
be done within the C<onClick> handler, and you need to finish it off using
C<return false> (ie, just like the example shows ;-)

B<Select List Events>

 <select name="mySelectList" size="10"
         onChange="OpenThought.CallUrl('/OpenThought/servercode.pl',
                                       'mySelectList')>

By using C<onChange> as we are above, whenever a select list item is clicked,
it will send it's value to /OpenThought/servercode.pl.

=head1 A CLOSER LOOK AT THE DEMO

This is the gist of what happens in the Soul Food Cafe demo.

Filling the menu select lists:

    $data->{menu} = [
            [ "Fried Chicken",   0 ],
            [ "Chicken Wings",   1 ],
            [ "Chicken Nuggets", 2 ],
            [ "Dry White Toast", 3 ],
            [ "Dry Wheat Toast", 4 ],
            [ "Coke",            5 ],
            [ "Sprite",          6 ],
        ];

    print $q->header;
    print $OT->parse_and_output( auto_param => $data });

The above will fill the following select list:

    <select name="menu" size="6"
            onChange="OpenThought.CallUrl('index.pl', 'menu', 'mode_get_info'>

If the user clicks a menu item, the onChange event fires.  It sends the
value of the highlighted menu item to index.pl.  We also send in an arbitrarily
named parameter of mode=get_info, which the Perl code can test on to know what
the user just clicked.

To return info about the "Fried Chicken", and display it in the html:

      $data-> {
          info => 'Best %*$# chicken in the state!',
          cost => '14.99',
      };

    print $q->header;
    $OT->param( $data );
    print $OT->response();

That updates the following html: (the data inside the span tags is replaced
with the data in the above hash):

    <span id="info">(no item selected)</span>
    <span id="cost">0.00</span>

To add an item to the dinner selection, the user clicks this button:

    <input type="button" value="Add Item -->"
           onClick="OpenThought.CallUrl('index.pl', 'menu', 'mode=add_item'>

The onClick even fires, and the currently highlighted menu item is again sent
to the server (but this time, we send in mode=add_item).  The server runs this:

    $data->{dinner} = ["Fried Chicken", 0];

    print $q->header;
    print $OT->param($data);

That appends the data to this select list:

    <select name="dinner" size="6">

The above code samples are all taken from the soulfoodcafe application which comes with
OpenThought.  Feel free to take a look at it for a complete example of an
OpenThought Application.

=head1 EXAMPLES

Here are some additional examples of how you might build an OpenThought
application.  Some of these examples are borrowed from the demo application.
Take a look at the demo app if you'd like more information.

=head2 Text, Password, and Textarea Form Elements

Client:

    <form name="myForm">

    <input type="text" name="textbox_example">
    <input type="button"
       onClick="OpenThought.CallUrl( 'text.pl', 'textbox_example')">
    </form>


Server:

    my $q  = CGI->new();
    my $OT = OpenThought->new();

    my $param = $q->param('textbox_example');
    warn("We were sent $param");

    my $field_data;
    $field_data->{'textbox_example'} = "Blah blah blah";

    print $q->header;
    $OT->param($field_data);
    print $OT->response();

=head2  Selectbox Form Elements

Client:

    <form name="myForm">

    <select name="selectbox_example">
        <option value="test">Test!
    </select>

    <input type="button"
       onClick="OpenThought.CallUrl( 'selectbox.pl', 'selectbox_example')">
    </form>

Server:

    my $q  = CGI->new();
    my $OT = OpenThought->new();

    my $param = $q->param('selectbox_example')";
    warn("We were sent $param");

    my $field_data
    $field_data->{'selectbox_example'} = [
                                           [ "Example 1", "ex_one"   ],
                                           [ "Example 2", "ex_two"   ],
                                           [ "Example 3", "ex_three" ],
                                         ];

    print $q->header;
    $OT->param($field_data);
    print $OT->response();


=head2  Radio Button HTML Elements

Client:

    <form name="myForm">

    <input type="radio" name="radio_example" value="ex_one" checked>
    <input type="radio" name="radio_example" value="ex_two">
    <input type="radio" name="radio_example" value="ex_three">
    <input type="radio" name="radio_example" value="ex_four">

    <input type=button
            onClick="OpenThought.CallUrl( 'radio.pl', 'radiobox_example')">
    </form>

Server:

    my $q  = CGI->new();
    my $OT = OpenThought->new();

    my $param = $q->param('radiobtn_example')";
    warn("We were sent $param");

    my $field_data;
    $field_data->{'radio_example'} = "ex_one";

    print $q->header;
    $OT->param($field_data);
    print $OT->response();

=head2  Checkbox HTML Elements

Client:

    <form name="myForm">

    <input type="checkbox" name="checkbox_example">
    <input type="button"
           onClick="OpenThought.CallUrl( 'checkbox.pl', 'checkbox_example')">
    </form>


Server:

    my $q  = CGI->new();
    my $OT = OpenThought->new();

    my $param = $q->param('checkbox_example')";
    warn("We were sent $param");

    my $field_data;
    $field_data->{'checkbox_example'} = "true";

    print $q->header;
    $OT->param($field_data);
    print $OT->response();

=head2  HTML Example

Client:

    <h2>
      <div id="html-example"><b>Old HTML</b></div>
    </h2>

    <input type="button"
           onClick="OpenThought.CallUrl( 'html.pl', 'html-example')">

Server:

    my $q  = CGI->new();
    my $OT = OpenThought->new();

    my $param = $q->param('html-example')";
    warn("We were sent $param");

    my $data;
    $data->{'html_example'} = "<i>New HTML</i>";

    print $q->header();
    $OT->param($data);
    print $OT->response();
 }

=head2  Image Example

Client:

     <img name="img_example" src="/images/image1.png">

     <input type="button"
            onClick="OpenThought.CallUrl( 'image.pl', 'image-example')">

Server:

    my $q  = CGI->new();
    my $OT = OpenThought->new();

    my $param = $q->param('img_example')";
    warn("We were sent image $param");

    my $data;
    $data->{'img_example'} = "/images/image2.png";

    print $q->header();
    $OT->param($data);
    print $OT->response();
 }

=head2  JavaScript Example

Client:

     onClick="OpenThought.CallUrl( 'javascript.pl' )">

Server:

    my $q  = CGI->new();
    my $OT = OpenThought->new();

    my $js = qq!var greet="Hello World"; alert(greet); !;

    print $q->header();
    $OT->javascript($js);
    $OT->response();
 }

=head1 EXAMPLE USING CGI::Application

=head2 The .pm File

This is an example package built using L<CGI::Application> together with
OpenThought.  This is just a package, you'll need an instance script (.pl file)
to call it.  That's just a handful of lines, and is well documented in
L<CGI::Application>.

 package Example;

 use strict;
 use base 'CGI::Application';
 use OpenThought();

 # Somewhat of a constructor -- called automatically by CGI::Application (and
 # before setup())
 sub cgiapp_init {
    my $self = shift;

    # Store the OpenThought object for later use
    $self->param('OpenThought' => OpenThought->new());

 }

 # Set up the run modes -- called automatically by CGI::Application
 sub setup {
     my $self = shift;

     $self->run_modes(
            'mode1' => 'init_example',
            'mode2' => 'some_screen',
            'mode3' => 'do_stuff',
            'mode4' => 'do_something_else',
            'mode5' => 'another_one',
     );

     $self->start_mode('mode1');
 }

 # The default run mode, called if no parameters were sent.  This would
 # normally return an html page (ie, the first page of the website).
 sub init_example {
    my $self = shift;

    my $OT = $self->param('OpenThought');

    return $self->show_html_for_initial_screen();

 }

 # An example run mode
 sub do_stuff {
    my $self = shift;
    my $q    = $self->query;
    my $OT   = $self->param('OpenThought');

    $data = {...};  # Assume we got some sort of interesting data here

    $OT->param($data);
    return $OT->response();
 }

=head1 AUTHOR

Eric Andreychek (eric at openthought.net)

=head1 THANKS TO

JJ < jj at jonallen dot info >
John Jewitt < john at jjspc dot demon dot co dot uk >
Buddy Burden < buddy at thinkgeek dot com >
Brent Ashley < brent at ashleyit dot com >
Greg Pomerantz < gmp216 at nyu dot edu >

=head1 COPYRIGHT and LICENSE

OpenThought is Copyright (c) 2000-2007 by Eric Andreychek.

This module is free software; you can redistribute it and/or modify it under the terms of either:

a) the GNU General Public License as published by the Free Software Foundation; either version 1, or (at
your option) any later version,

or

b) the "Artistic License" which comes with this module.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See either the GNU General
Public License or the Artistic License for more details.

=head1 BUGS

Bug hunting season has been good.  All known bugs have been
eradicated.  If you happen to run across one, please let me know and I'd be
more then happy to take care of it.  But real hackers would send a patch ;-)

=head1 SEE ALSO

L<CGI|CGI>

L<CGI::Application|CGI::Application>

