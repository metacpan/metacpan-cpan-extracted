package OpenInteract::UI::Main;

# $Id: Main.pm,v 1.11 2003/08/13 03:16:44 lachoy Exp $

use strict;

$OpenInteract::UI::Main::VERSION = sprintf("%d.%02d", q$Revision: 1.11 $ =~ /(\d+)\.(\d+)/);

sub handler {
    my ( $class ) = @_;
    my $R = OpenInteract::Request->instance;

    # Put the Popup and other directives here. (See DIRECTIVES in POD.)

    if ( my $directive = $R->{ui}{directive} ) { 
        if ( $directive =~ /^(NoTmpl|NoTemplate)$/ ) {
            $R->{page}{_no_template_}++;
            $R->DEBUG && $R->scrib( 1, "Using NO window template" );
        }
        else {
            $R->{page}{_template_key_} = $R->CONFIG->{page_directives}{ $directive };
            $R->DEBUG && $R->scrib( 1, "Using template key from directive: ",
                                       "[$R->{page}{_template_key_}]" );
        }
    }

    # Parse the URL and the information for our first action

    my $action_info = $R->lookup_action( undef, { return => 'info' } );
    my ( $action_class, $action_method ) = ( $action_info->{class},
                                             $action_info->{method} );
    $R->DEBUG && $R->scrib( 1, "Action info [$action_class] [$action_method]" );

    # Capture any die() commands thrown; note that any error handler that
    # throws a die() needs to also return content to display; otherwise
    # it will be a pretty boring (empty) page :)

    $R->{page}{content} = eval { $action_class->$action_method({
                                        path   => $R->{path}{current},
                                        ACTION => $action_info }) };
    if ( $@ ) {
        $R->{page}{content} = $@;
        $R->scrib( 0, "Action died. Here is what it left: $@" );
    }

    # Check to see if we're supposed to send back a file (no content
    # to return) or we're doing an HTTP redirect

    if ( $R->{page}{send_file} || $R->{page}{http_redirect} ) {
        return undef;
    }

    # Otherwise pick the template to wrap the content in

    my $template_name = $class->choose_template;
    $R->DEBUG && $R->scrib( 1, "Using template [$template_name] for full page" );
    return $R->{page}{content} unless ( $template_name );

    $R->{main_template_vars} ||= {};
    return $R->template->handler( {},
                                  { %{ $R->{main_template_vars} },
                                    page => $R->{page},
                                    path => $R->{path}{original} },
                                  { name => $template_name } );
}


sub choose_template {
    my ( $class ) = @_;
    my $R = OpenInteract::Request->instance;

    return undef if ( $R->{page}{_no_template_} );

    my $template_name = $R->{page}{_template_name_};

    # If the template name isn't specified by the request, look for a
    # template key which we can use to find the template in the theme.

    unless ( $template_name ) {
        my $template_key  = $R->{page}{_template_key_};
        $template_key   ||= 'simple_template' if ( $R->{page}{_simple_} );
        $template_key   ||= 'main_template';
        $template_name    = $R->{theme}->property_value( $template_key );
    }
    return $template_name;
}

1;

__END__

=head1 NAME

OpenInteract::UI::Main - The primary user interface assembly 'conductor'

=head1 SYNOPSIS

 my $page = OpenInteract::UI::Main->handler();
 send_http_headers();
 print $page;

 # Subclass to define a new method for looking up template names:

 package OpenInteract::UI::LanguageChoice;

 use base qw( OpenInteract::UI::Main );

 my $DEFAULT_LANGUAGE = 'en';

 sub choose_template {
     my ( $class ) = @_;
     my ( $language );
     if ( $R->{auth}{is_logged_in} ) {
         $language = $R->{auth}{user}->language;
     }
     $language ||= $R->apache->param( 'lang' )
                   || $R->{session}{lang}
                   || $DEFAULT_LANGUAGE;
     my $R = OpenInteract::Request->instance;
     my $template = $R->{theme}->property_value( "template_$language" )
                    || $R->{theme}->property_value( 'main_template' );
     return $template;
 }

=head1 DESCRIPTION

This is the handler that puts the main content generated together with
the template that surrounds the content on every page.

The action has already been parsed from the URL for us so we look up
the class/method used to generate the content and call them. We then
put that content into the main template which is specified in our
theme, unless we have received another directive to use a separate
template or no template at all.

Another alternative is that the content handler needs to return a file
that is not HTML, such as a PDF, graphic, word processing document,
archive, or whatever. If so the content handler should put the
B<complete filename> in the $R-E<gt>{page}-E<gt>{send_file} key.

A content author can set a main template to use for the generated
content by setting:

 $R->{page}{_template_name_}

to the name of the template to use. This should be a fully-qualified
template name -- such as 'mypkg::mytemplate'. If you do not specify a
package the OI template provider will try to find the template in the
global template directory.

You can also set a template that might vary by theme. This is not the
name of the template directly but rather a placeholder within the
theme which holds the name of the template. For instance, say you
created a 'spooky_template' and implemented it in multiple
themes. Even though you as an author do not know what theme will be
used, you can still pick the right template by setting:

 $R->{page}{_template_key_}

And to use the 'simple' template, the author should set:

 $R->{page}{_simple_}

to a true value. The default 'simple' template is 'base_simple',
although you can set its name under the C<template_names> key of your
server configuration.

Finally, the author can also set:

 $R->{page}{_no_template_}

to display the content without a template at all.

=head2 Main Template Variables

Any content handler can send information to be placed directly onto
the main template by setting information using the
$R-E<gt>{main_template_vars} hashref. For instance:

 $R->{main_template_vars}{current_weather} = 'Rainy and cold';

would set the 'current_weather' template variable for display on the
main template and B<not> on any of the content handlers.

Note that while this sounds useful (and it can be), you will probably
use it only very rarely. The 'boxes' concept is more comprehensive and
full-featured and will almost certainly do what you need.

=head1 METHODS

B<handler()>

Performs the actions described above. Returns either a single scalar
with the full page generated or undef, in which case the information
to be sent is likely a non-HTML page that needs to be sent on its own.

B<choose_template()>

Class method to find the template name to wrap the content in. If
undef is returned then C<handler()> just returns the raw
content. Otherwise we use the return value as the template name.

Here are the steps we execute, in order, to find the main template
name:

=over 4

=item 1.

If C<$R-E<gt>{page}{_no_template_}> is true we return undef.

=item 2.

If C<$R-E<gt>{page}{_template_name_}> is defined we return it.

=item 3.

If C<$R-E<gt>{page}{_template_key_}> is defined we return the value of
that key in the current theme.

=item 4.

If C<$R-E<gt>{page}{_simple_}> is defined we return the value of
'simple_template' in the current theme.

=item 5.

We return the value of 'main_template' in the current theme.

=back

=head1 DIRECTIVES

A directive (or 'page directive') is placed before the relevant action
in the URL and tells OpenInteract to display the content in a certain
manner. The directive should have been parsed out in the main content
handler (OpenInteract.pm).

For instance:

 /Popup/User/show/?user_id=716

Says that OI should use the template corresponding to 'Popup' to
display the action 'User'. The correspondence is currently done in
this handler but this will change shortly.

The directives used are listed in the server configuration under the
C<page_directives> key.

=head1 TO DO

Nothing known, beyond write different ones of these (SOAP, etc.)

=head1 BUGS

None known.

=head1 COPYRIGHT

Copyright (c) 2001-2002 intes.net, inc.. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters <chris@cwinters.com>
