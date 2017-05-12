#------------------------------------------------------------------------------
#
# Net::SMS::Web::Action utility module
#
#------------------------------------------------------------------------------

package Net::SMS::Web::Action;

use Class::Struct;

struct(
    'Net::SMS::Web::Action' => {
        url     => '$',
        method  => '$',
        agent   => '$',
        params  => '%',
    }
);

package Net::SMS::Web;

$VERSION = '0.015';

use strict;
use warnings;

#------------------------------------------------------------------------------
#
# Standard pragmas
#
#------------------------------------------------------------------------------

use LWP::UserAgent;
use CGI::Enurl;
use CGI::Lite;
use URI;

#------------------------------------------------------------------------------
#
# POD
#
#------------------------------------------------------------------------------

=head1 NAME

Net::SMS::Web - a generic module for sending SMS messages using web2sms
gateways (e.g. L<http://www.mtnsms.com/> or L<http://www.o2.co.uk/>).

=head1 DESCRIPTION

A perl module to send SMS messages, using web2sms gateways. This module
should be subclassed for a particular gateway (see L<Net::SMS::O2> or
L<Net::SMS::Mtnsms>).

When you subclass this class, you need to make a series of calls to the
L<action> method, passing a L<Net::SMS::Web::Action> object which should
correspond to the web form acions that are required to send an SMS message via
the web gateway in question.

The HTTP requests are sent using the LWP::UserAgent module. If you are using a
proxy, you may need to set the HTTP_PROXY environment variable for this to
work (see L<LWP::UserAgent>).

=cut

#------------------------------------------------------------------------------
#
# Package globals
#
#------------------------------------------------------------------------------

use vars qw( $DEFAULT_AGENT );

$DEFAULT_AGENT = 'Mozilla/4.0 (compatible; MSIE 4.01; Windows NT)';

#------------------------------------------------------------------------------
#
# More POD ...
#
#------------------------------------------------------------------------------

=head1 CONSTRUCTOR

The constructor of this class can be overridden in a subclass as follows:

    sub new
    {
        my $class = shift;
        my $self = $class->SUPER::new( @_ );
        $self->_init( @_ );
        return $self;
    }

=cut

sub new
{
    my $class = shift;
    my $self = bless {}, $class;
    $self->{COOKIES} = {};
    return $self;
}

sub _get_cookies
{
    my $self = shift;
    my $response = shift;

    for ( grep s{;.*}{}, $response->header( 'Set-Cookie' ) )
    {
        if ( /^(.*?)=(.*)$/ )
        {
            $self->{COOKIES}{$1} = $2;
        }
    }
}

#------------------------------------------------------------------------------
#
# More POD ...
#
#------------------------------------------------------------------------------

=head1 METHODS

=cut

=head2 cookie( $key )

This method gets the value of a cookie that has been set either in a
previous action, or in a redirected Location resulting from one of those
actions.

=cut

sub cookie
{
    my $self = shift;
    my $key = shift;
    return $self->{COOKIES}{$key};
}

=head2 response()

This method gets the body of the response to the previous action.

=cut

sub response
{
    my $self = shift;
    return $self->{RESPONSE};
}

=head2 action

This method takes an L<Net::SMS::Web::Action> object as an argument, and
performs the corresponding action. It takes care of retention of cookies set by
previous actions, and follows any redirection that result from the submission
of the action.

=cut

sub action
{
    my $self = shift;
    my $action = shift;

    die "Action should be a Net::SMS::Web::Action object\n" 
        unless ref( $action ) eq 'Net::SMS::Web::Action'
    ;

    my $url = $action->url;
    my %params = $action->params ? %{ $action->params } : ();
    my $method = $action->method || 'GET';
    my $agent = $action->agent || $DEFAULT_AGENT;
    my $params = enurl \%params;

    my $request;

    if ( $method =~ /^(GET|HEAD)$/ )
    {
        $url .= "?$params" if $params;
        $request = HTTP::Request->new( $method, $url );
    }
    elsif ( $method eq 'POST' )
    {
        $request = HTTP::Request->new( $method, $url );
        $request->content( $params ) if $params;
        $request->content_type( 'application/x-www-form-urlencoded' );
    }
    else
    {
        die "Unknown method $method - should be GET or POST\n";
    }

    $request->header( 'Accept' => 'text/html' );
    $request->header( 'Referer' => $self->{REFERER} ) if $self->{REFERER};
    $request->header( 
        'Cookie' => 
            join( ';', 
                map { "$_=$self->{COOKIES}{$_}" } keys %{$self->{COOKIES}} 
            )
        ) if $self->{COOKIES} and %{$self->{COOKIES}}
    ;
    if ( $self->{verbose} )
    {
        my $r = $request->as_string();
        $r =~ s/^(\S)/\t$1/gm;
        print STDERR "REQUEST\n$r\n\n";
    }
    my $ua = LWP::UserAgent->new;
    $ua->env_proxy();
    $ua->agent( $agent );
    my $response = $ua->simple_request( $request );
    $self->{RESPONSE} = $response->content();
    $self->{REFERER} = $url;
    if ( $self->{verbose} )
    {
        my $r = $response->headers_as_string();
        $r =~ s/^/\t/gm;
    }
    if ( $response->is_error )
    {
        die
            ref($self), ": ", $request->uri,
            " failed:\n\t", 
            $response->status_line, 
            "\n"
        ;
    }
    if ( $self->{audit_trail} and -d $self->{audit_trail} )
    {
        $self->{audit_count}++;
        my $audit_file = "$self->{audit_trail}/$self->{audit_count}.html";
        open( FH, ">$audit_file" ) and print FH $self->{RESPONSE};
        close( FH );
    }
    $self->_get_cookies( $response );
    my $location = $response->header( 'Location' );
    if ( $location )
    {
        $action->url( URI->new_abs( $location, $action->url ) );
        return $self->action( $action );
    }
}

#------------------------------------------------------------------------------
#
# More POD ...
#
#------------------------------------------------------------------------------

=head1 BUGS

Bugs can be submitted to the CPAN RT bug tracker either via email
(bug-net-sms-web@rt.cpan.org) or web
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-SMS-Web>. There is also a
sourceforge project at L<http://sourceforge.net/projects/net-sms-web/>.

=head1 AUTHOR

Ave Wrigley <Ave.Wrigley@itn.co.uk>

=head1 COPYRIGHT

Copyright (c) 2001 Ave Wrigley. All rights reserved. This program is free
software; you can redistribute it and/or modify it under the same terms as Perl
itself.

=cut

#------------------------------------------------------------------------------
#
# End of POD
#
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
#
# True ...
#
#------------------------------------------------------------------------------

1;
