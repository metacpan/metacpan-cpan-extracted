package OpenInteract::Cookies::Apache;

# $Id: Apache.pm,v 1.5 2002/01/02 02:43:53 lachoy Exp $

use strict;
use Apache::Cookie;
use Data::Dumper qw( Dumper );

@OpenInteract::Cookies::Apache::ISA     = ();
$OpenInteract::Cookies::Apache::VERSION = sprintf("%d.%02d", q$Revision: 1.5 $ =~ /(\d+)\.(\d+)/);


# Retrieve the cookies using Apache::Request

sub parse {
    my ( $class ) = @_;
    my $R = OpenInteract::Request->instance;
    my $cookie_info = Apache::Cookie->fetch;
    foreach my $name ( keys %{ $cookie_info } ) {
        my $value = $cookie_info->{ $name }->value;
        $R->DEBUG && $R->scrib( 2, "Getting cookie $name to $value" );
        $R->{cookie}{in}{ $name } = $value;
    }
    return $R->{cookie}{in};
}


# Cycle through the Apache::Cookie objects and 
# call the bake method, which puts the appropriate header
# into the outgoing headers table.

sub bake {
    my ( $class ) = @_;
    my $R = OpenInteract::Request->instance;
    foreach my $name ( keys %{ $R->{cookie}{out} } ) {
        $R->DEBUG && $R->scrib( 2, "Setting $name to value ", $R->{cookie}{out}{ $name }->value );
        $R->{cookie}{out}{ $name }->bake;
    }
    return 1;
}


# Create a new cookie

sub create_cookie {
    my ( $class, $p ) = @_;
    my $R = OpenInteract::Request->instance;
    return $R->{cookie}{out}{ $p->{name} } = 
                    Apache::Cookie->new( $R->apache, 
                                         -name => $p->{name}, 
                                         -value => $p->{value},
                                         -path => $p->{path}, 
                                         -expires => $p->{expires} );
}

1;

__END__

=pod

=head1 NAME

OpenInteract::Cookies::Apache - handler to parse/output cookies from/to the client using Apache::Cookie

=head1 SYNOPSIS

 # In your website's 'conf/server.perl' file:

 # Use Apache::Cookie (from Apache::Request)

 'system_alias' => {
       cookies => 'OpenInteract::Cookies::Apache', ...
 }

 # Retrieve the cookies from the client request

 $R->cookies->parse;

 # Place cookies in the outbound content header

 $R->cookies->bake;

 # Retrieve a cookie value in an OpenInteract content handler

 $params->{search} = $R->{cookie}{in}{search_value};
 
 # Create a new cookie

 $R->cookies->create_cookie({ name    => 'search_value',
                              expires => '+3M',
                              value   => 'this AND that' });

 # Expire an old cookie

 $R->cookies->create_cookie({ name    => 'search_value',
                              expires => '-3d',
                              value   => undef });

=head1 DESCRIPTION

This module defines methods for retrieving, setting and creating
cookies. If you do not know what a cookie is, check out:

 http://www.ics.uci.edu/pub/ietf/http/rfc2109.txt

OpenInteract currently uses one of two modules to perform these
actions. They adhere to the same interface but perform the actions
using different helper modules. This module uses L<Apache::Cookie> to
do the actual cookie actions.

Note that L<Apache::Cookie|Apache::Cookie> does not work on all
platforms, particularly Win32 (as of this writing). If
L<Apache::Cookie|Apache::Cookie> does not work for you, please use the
L<OpenInteract::Cookies::CGI|OpenInteract::Cookies::CGI> module
instead.

To use this implementation, set the following key in the
C<conf/server.perl> file for your website:

 system_aliases => {
   cookies => 'OpenInteract::Cookies::Apache', ...
 },

=head1 METHODS

Methods for this class.

B<create_cookie( \%params  )>

This function is probably the only one you will ever use from this
module. Pass in normal parameters (see below) and the function will
create a cookie and put it into $R for you.

Parameters:

=over 4

=item *

name ($) (required)

Name of cookie

=item *

value ($ (required)

Value of cookie

=item *

expires ($ (optional)

When it expires ( '+3d', etc.). Note that negative values (e.g., '-3d'
will expire the cookie on most browsers. Leaving this value empty or
undefined will create a 'short-lived' cookie, meaning it will expire
when the user closes her browser.

=item *

path ($) (optional)

Path it responds to

=back

B<parse()>

Read in the cookies passed to this request and file them into the
hashref:

 $R->{cookie}{in}

with the key as the cookie name.

B<bake()>

Puts the cookies from $R-E<gt>{cookie}-E<gt>{out} into the outgoing
headers.

=head1 TO DO

Nothing.

=head1 BUGS

None known.

=head1 SEE ALSO

L<Apache::Cookie|Apache::Cookie>

=head1 COPYRIGHT

Copyright (c) 2001-2002 intes.net, inc.. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters <chris@cwinters.com>

=cut
