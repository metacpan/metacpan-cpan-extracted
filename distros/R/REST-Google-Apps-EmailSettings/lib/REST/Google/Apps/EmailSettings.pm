package REST::Google::Apps::EmailSettings;

use Carp;
use LWP::UserAgent;
use XML::Simple;

use strict;
use warnings;

our $VERSION = '1.1.6';



sub new {
    my $self = bless {}, shift;

    my ( $arg );
    %{$arg} = @_;

    map { $arg->{lc($_)} = $arg->{$_} } keys %{$arg};

    $self->{'domain'} = $arg->{'domain'} || croak( "Missing required 'domain' argument" );

    $self->{'lwp'} = LWP::UserAgent->new();
    $self->{'lwp'}->agent( 'RESTGoogleAppsEmailSettings/' . $VERSION );

    if ( $arg->{'username'} && $arg->{'password'} ) {
        $self->authenticate(
            'username' => $arg->{'username'},
            'password' => $arg->{'password'}
        )
        || croak qq(Unable to retrieve authentication token);
    }

    $self->{'xml'} = XML::Simple->new();

    return( $self );
}



sub authenticate {
    my $self = shift;

    return( 1 ) if $self->{'token'};

    my ( $arg );
    %{$arg} = @_;

    map { $arg->{lc($_)} = $arg->{$_} } keys %{$arg};

    foreach my $param ( qw/ username password / ) {
        $arg->{$param} || croak( "Missing required '$param' argument" );
    }

    my $response = $self->{'lwp'}->post(
        'https://www.google.com/accounts/ClientLogin',
        [
            'accountType' => 'HOSTED',
            'service'     => 'apps',
            'Email'       => $arg->{'username'} . '@' . $self->{'domain'},
            'Passwd'      => $arg->{'password'}
        ]
    );

    $response->is_success() || return( 0 );

    foreach ( split( /\n/, $response->content() ) ) {
        $self->{'token'} = $1 if /^Auth=(.+)$/;
        last if $self->{'token'};
    }

    return( 1 ) if $self->{'token'} || return( 0 );
}



sub createLabel {
    my $self = shift;

    my ( $arg );
    %{$arg} = @_;

    map { $arg->{lc($_)} = $arg->{$_} } keys %{$arg};

    foreach my $param ( qw/ username label / ) {
        $arg->{$param} || croak( "Missing required '$param' argument" );
    }

    my $url = qq(https://apps-apis.google.com/a/feeds/emailsettings/2.0/$self->{'domain'}/$arg->{'username'}/label);

    my ( $body );

    $body  = $self->_xmlpre();

    $body .= qq(  <apps:property name="label" value="$arg->{'label'}" />\n);

    $body .= $self->_xmlpost();

    my $result = $self->_request(
        'method' => 'POST',
        'url'    => $url,
        'body'   => $body
    ) || return( 0 );

    return( 1 );
}



sub createFilter {
    my $self = shift;

    my ( $arg );
    %{$arg} = @_;

    map { $arg->{lc($_)} = $arg->{$_} } keys %{$arg};

    foreach my $param ( qw/ username / ) {
        $arg->{$param} || croak( "Missing required '$param' argument" );
    }

    unless (
        $arg->{'from'} || $arg->{'to'} || $arg->{'subject'} || $arg->{'hasword'} || $arg->{'noWord'} || $arg->{'attachment'}
    ) {
        croak( "Missing required filter criteria" );
    }

    unless (
        $arg->{'label'} || $arg->{'markasread'} || $arg->{'archive'}
    ) {
        croak( "Missing required filter action" );
    }

    my $url = qq(https://apps-apis.google.com/a/feeds/emailsettings/2.0/$self->{'domain'}/$arg->{'username'}/filter);

    my ( $body );

    $body  = $self->_xmlpre();

    foreach my $param ( qw/ from to subject / ) {
        $body .= qq(  <apps:property name="$param" value="$arg->{$param}" />\n) if $arg->{$param};
    }

    $body .= qq(  <apps:property name="hasTheWord" value="$arg->{'hasword'}" />\n) if $arg->{'hasword'};
    $body .= qq(  <apps:property name="doesNotHaveTheWord" value="$arg->{'noword'}" />\n) if $arg->{'noword'};
    $body .= qq(  <apps:property name="hasAttachment" value="$arg->{'attachment'}" />\n) if $arg->{'attachment'};

    $body .= qq(  <apps:property name="label" value="$arg->{'label'}" />\n) if $arg->{'label'};
    $body .= qq(  <apps:property name="shouldMarkAsRead" value="$arg->{'markasread'}" />\n) if $arg->{'markasread'};
    $body .= qq(  <apps:property name="shouldArchive" value="$arg->{'archive'}" />\n) if $arg->{'archive'};

    $body .= $self->_xmlpost();

    my $result = $self->_request(
        'method' => 'POST',
        'url'    => $url,
        'body'   => $body
    ) || return( 0 );

    return( 1 );
}



sub createSendAs {
    my $self = shift;

    my ( $arg );
    %{$arg} = @_;

    map { $arg->{lc($_)} = $arg->{$_} } keys %{$arg};

    foreach my $param ( qw/ username name address / ) {
        $arg->{$param} || croak( "Missing required '$param' argument" );
    }

    my $url = qq(https://apps-apis.google.com/a/feeds/emailsettings/2.0/$self->{'domain'}/$arg->{'username'}/sendas);

    my ( $body );

    $body  = $self->_xmlpre();

    $body .= qq(  <apps:property name="name" value="$arg->{'name'}" />\n);
    $body .= qq(  <apps:property name="address" value="$arg->{'address'}" />\n);
    $body .= qq(  <apps:property name="replyTo" value="$arg->{'replyto'}" />\n) if $arg->{'replyto'};
    $body .= qq(  <apps:property name="makeDefault" value="$arg->{'default'}" />\n) if $arg->{'default'};

    $body .= $self->_xmlpost();

    my $result = $self->_request(
        'method' => 'POST',
        'url'    => $url,
        'body'   => $body
    ) || return( 0 );

    return( 1 );
}



sub enableWebClips {
    my $self = shift;

    my ( $arg );
    %{$arg} = @_;

    map { $arg->{lc($_)} = $arg->{$_} } keys %{$arg};

    foreach my $param ( qw/ username / ) {
        $arg->{$param} || croak( "Missing required '$param' argument" );
    }

    my $url = qq(https://apps-apis.google.com/a/feeds/emailsettings/2.0/$self->{'domain'}/$arg->{'username'}/webclip);

    my ( $body );

    $body  = $self->_xmlpre();

    $body .= qq(  <apps:property name="enable" value="true" />\n);

    $body .= $self->_xmlpost();

    my $result = $self->_request(
        'method' => 'PUT',
        'url'    => $url,
        'body'   => $body
    ) || return( 0 );

    return( 1 );
}

sub disableWebClips {
    my $self = shift;

    my ( $arg );
    %{$arg} = @_;

    map { $arg->{lc($_)} = $arg->{$_} } keys %{$arg};

    foreach my $param ( qw/ username / ) {
        $arg->{$param} || croak( "Missing required '$param' argument" );
    }

    my $url = qq(https://apps-apis.google.com/a/feeds/emailsettings/2.0/$self->{'domain'}/$arg->{'username'}/webclip);

    my ( $body );

    $body  = $self->_xmlpre();

    $body .= qq(  <apps:property name="enable" value="false" />\n);

    $body .= $self->_xmlpost();

    my $result = $self->_request(
        'method' => 'PUT',
        'url'    => $url,
        'body'   => $body
    ) || return( 0 );

    return( 1 );
}



sub enableForwarding {
    my $self = shift;

    my ( $arg );
    %{$arg} = @_;

    map { $arg->{lc($_)} = $arg->{$_} } keys %{$arg};

    foreach my $param ( qw/ username forwardto / ) {
        $arg->{$param} || croak( "Missing required '$param' argument" );
    }

    my $url = qq(https://apps-apis.google.com/a/feeds/emailsettings/2.0/$self->{'domain'}/$arg->{'username'}/forwarding);

    my ( $body );

    $body  = $self->_xmlpre();

    $body .= qq(  <apps:property name="enable" value="true" />\n);
    $body .= qq(  <apps:property name="forwardTo" value="$arg->{'forwardto'}" />\n);

    if ( $arg->{'action'} ) {
        $arg->{'action'} = uc( $arg->{'action'} );

        $body .= qq(  <apps:property name="action" value="$arg->{'action'}" />\n);
    }
    else {
        $body .= qq(  <apps:property name="action" value="KEEP" />\n);
    }

    $body .= $self->_xmlpost();

    my $result = $self->_request(
        'method' => 'PUT',
        'url'    => $url,
        'body'   => $body
    ) || return( 0 );

    return( 1 );
}

sub disableForwarding {
    my $self = shift;

    my ( $arg );
    %{$arg} = @_;

    map { $arg->{lc($_)} = $arg->{$_} } keys %{$arg};

    foreach my $param ( qw/ username / ) {
        $arg->{$param} || croak( "Missing required '$param' argument" );
    }

    my $url = qq(https://apps-apis.google.com/a/feeds/emailsettings/2.0/$self->{'domain'}/$arg->{'username'}/forwarding);

    my ( $body );

    $body  = $self->_xmlpre();

    $body .= qq(  <apps:property name="enable" value="false" />\n);

    $body .= $self->_xmlpost();

    my $result = $self->_request(
        'method' => 'PUT',
        'url'    => $url,
        'body'   => $body
    ) || return( 0 );

    return( 1 );
}



sub enablePOP {
    my $self = shift;

    my ( $arg );
    %{$arg} = @_;

    map { $arg->{lc($_)} = $arg->{$_} } keys %{$arg};

    foreach my $param ( qw/ username / ) {
        $arg->{$param} || croak( "Missing required '$param' argument" );
    }

    my $url = qq(https://apps-apis.google.com/a/feeds/emailsettings/2.0/$self->{'domain'}/$arg->{'username'}/pop);

    my ( $body );

    $body  = $self->_xmlpre();

    $body .= qq(  <apps:property name="enable" value="true" />\n);

    if ( $arg->{'enableFor'} ) {
        if ( $arg->{'enablefor'} eq 'all' ) { $arg->{'enablefor'} = 'ALL_MAIL'; }
        if ( $arg->{'enablefor'} eq 'now' ) { $arg->{'enablefor'} = 'MAIL_FROM_NOW_ON'; }

        $body .= qq( <apps:property name="enableFor" value="$arg->{'enablefor'}" />\n);
    }
    else {
        $body .= qq( <apps:property name="enableFor" value="MAIL_FROM_NOW_ON" />\n);
    }

    if ( $arg->{'action'} ) {
        $arg->{'action'} = uc( $arg->{'action'} );

        $body .= qq(  <apps:property name="action" value="$arg->{'action'}" />\n);
    }
    else {
        $body .= qq(  <apps:property name="action" value="KEEP" />\n);
    }

    $body .= $self->_xmlpost();

    my $result = $self->_request(
        'method' => 'PUT',
        'url'    => $url,
        'body'   => $body
    ) || return( 0 );

    return( 1 );

}

sub disablePOP {
    my $self = shift;

    my ( $arg );
    %{$arg} = @_;

    map { $arg->{lc($_)} = $arg->{$_} } keys %{$arg};

    foreach my $param ( qw/ username / ) {
        $arg->{$param} || croak( "Missing required '$param' argument" );
    }

    my $url = qq(https://apps-apis.google.com/a/feeds/emailsettings/2.0/$self->{'domain'}/$arg->{'username'}/pop);

    my ( $body );

    $body  = $self->_xmlpre();

    $body .= qq(  <apps:property name="enable" value="false" />\n);

    $body .= $self->_xmlpost();

    my $result = $self->_request(
        'method' => 'PUT',
        'url'    => $url,
        'body'   => $body
    ) || return( 0 );

    return( 1 );
}


sub enableIMAP {
    my $self = shift;

    my ( $arg );
    %{$arg} = @_;

    map { $arg->{lc($_)} = $arg->{$_} } keys %{$arg};

    foreach my $param ( qw/ username / ) {
        $arg->{$param} || croak( "Missing required '$param' argument" );
    }

    my $url = qq(https://apps-apis.google.com/a/feeds/emailsettings/2.0/$self->{'domain'}/$arg->{'username'}/imap);

    my ( $body );

    $body  = $self->_xmlpre();

    $body .= qq(  <apps:property name="enable" value="true" />\n);

    $body .= $self->_xmlpost();

    my $result = $self->_request(
        'method' => 'PUT',
        'url'    => $url,
        'body'   => $body
    ) || return( 0 );

    return( 1 );
}

sub disableIMAP {
    my $self = shift;

    my ( $arg );
    %{$arg} = @_;

    map { $arg->{lc($_)} = $arg->{$_} } keys %{$arg};

    foreach my $param ( qw/ username / ) {
        $arg->{$param} || croak( "Missing required '$param' argument" );
    }

    my $url = qq(https://apps-apis.google.com/a/feeds/emailsettings/2.0/$self->{'domain'}/$arg->{'username'}/imap);

    my ( $body );

    $body  = $self->_xmlpre();

    $body .= qq(  <apps:property name="enable" value="false" />\n);

    $body .= $self->_xmlpost();

    my $result = $self->_request(
        'method' => 'PUT',
        'url'    => $url,
        'body'   => $body
    ) || return( 0 );

    return( 1 );
}



sub enableVacation {
    my $self = shift;

    my ( $arg );
    %{$arg} = @_;

    map { $arg->{lc($_)} = $arg->{$_} } keys %{$arg};

    foreach my $param ( qw/ username subject message / ) {
        $arg->{$param} || croak( "Missing required '$param' argument" );
    }

    my $url = qq(https://apps-apis.google.com/a/feeds/emailsettings/2.0/$self->{'domain'}/$arg->{'username'}/vacation);

    my ( $body );

    $body  = $self->_xmlpre();

    $body .= qq(  <apps:property name="enable" value="true" />\n);
    $body .= qq(  <apps:property name="subject" value="$arg->{'subject'}" />\n);
    $body .= qq(  <apps:property name="message" value="$arg->{'message'}" />\n);
    $body .= qq(  <apps:property name="contactsOnly" value="$arg->{'contactsonly'}" />\n) if $arg->{'contactsonly'};

    $body .= $self->_xmlpost();

    my $result = $self->_request(
        'method' => 'PUT',
        'url'    => $url,
        'body'   => $body
    ) || return( 0 );

    return( 1 );
}

sub disableVacation {
    my $self = shift;

    my ( $arg );
    %{$arg} = @_;

    map { $arg->{lc($_)} = $arg->{$_} } keys %{$arg};

    foreach my $param ( qw/ username / ) {
        $arg->{$param} || croak( "Missing required '$param' argument" );
    }

    my $url = qq(https://apps-apis.google.com/a/feeds/emailsettings/2.0/$self->{'domain'}/$arg->{'username'}/vacation);

    my ( $body );

    $body  = $self->_xmlpre();

    $body .= qq(  <apps:property name="enable" value="false" />\n);

    $body .= $self->_xmlpost();

    my $result = $self->_request(
        'method' => 'PUT',
        'url'    => $url,
        'body'   => $body
    ) || return( 0 );

    return( 1 );
}



sub enableSignature {
    my $self = shift;

    my ( $arg );
    %{$arg} = @_;

    map { $arg->{lc($_)} = $arg->{$_} } keys %{$arg};

    foreach my $param ( qw/ username signature / ) {
        $arg->{$param} || croak( "Missing required '$param' argument" );
    }

    my $url = qq(https://apps-apis.google.com/a/feeds/emailsettings/2.0/$self->{'domain'}/$arg->{'username'}/signature);

    my ( $body );

    $body  = $self->_xmlpre();

    $body .= qq(  <apps:property name="signature" value="$arg->{'signature'}" />\n);

    $body .= $self->_xmlpost();

    my $result = $self->_request(
        'method' => 'PUT',
        'url'    => $url,
        'body'   => $body
    ) || return( 0 );

    return( 1 );
}

sub disableSignature {
    my $self = shift;

    my ( $arg );
    %{$arg} = @_;

    map { $arg->{lc($_)} = $arg->{$_} } keys %{$arg};

    foreach my $param ( qw/ username / ) {
        $arg->{$param} || croak( "Missing required '$param' argument" );
    }

    my $url = qq(https://apps-apis.google.com/a/feeds/emailsettings/2.0/$self->{'domain'}/$arg->{'username'}/signature);

    my ( $body );

    $body  = $self->_xmlpre();

    $body .= qq(  <apps:property name="signature" value="" />\n);

    $body .= $self->_xmlpost();

    my $result = $self->_request(
        'method' => 'PUT',
        'url'    => $url,
        'body'   => $body
    ) || return( 0 );

    return( 1 );
}



sub setLanguage {
    my $self = shift;

    my ( $arg );
    %{$arg} = @_;

    map { $arg->{lc($_)} = $arg->{$_} } keys %{$arg};

    foreach my $param ( qw/ username language / ) {
        $arg->{$param} || croak( "Missing required '$param' argument" );
    }

    my $url = qq(https://apps-apis.google.com/a/feeds/emailsettings/2.0/$self->{'domain'}/$arg->{'username'}/language);

    my ( $body );

    $body  = $self->_xmlpre();

    $body .= qq(  <apps:property name="language" value="$arg->{'language'}" />\n);

    $body .= $self->_xmlpost();

    my $result = $self->_request(
        'method' => 'PUT',
        'url'    => $url,
        'body'   => $body
    ) || return( 0 );

    return( 1 );
}



sub setPageSize {
    my $self = shift;

    my ( $arg );
    %{$arg} = @_;

    map { $arg->{lc($_)} = $arg->{$_} } keys %{$arg};

    foreach my $param ( qw/ username pagesize / ) {
        $arg->{$param} || croak( "Missing required '$param' argument" );
    }

    my $url = qq(https://apps-apis.google.com/a/feeds/emailsettings/2.0/$self->{'domain'}/$arg->{'username'}/general);

    my ( $body );

    $body  = $self->_xmlpre();

    $body .= qq(  <apps:property name="pageSize" value="$arg->{'pagesize'}" />\n);

    $body .= $self->_xmlpost();

    my $result = $self->_request(
        'method' => 'PUT',
        'url'    => $url,
        'body'   => $body
    ) || return( 0 );

    return( 1 );
}



sub enableShortcuts {
    my $self = shift;

    my ( $arg );
    %{$arg} = @_;

    map { $arg->{lc($_)} = $arg->{$_} } keys %{$arg};

    foreach my $param ( qw/ username / ) {
        $arg->{$param} || croak( "Missing required '$param' argument" );
    }

    my $url = qq(https://apps-apis.google.com/a/feeds/emailsettings/2.0/$self->{'domain'}/$arg->{'username'}/general);

    my ( $body );

    $body  = $self->_xmlpre();

    $body .= qq(  <apps:property name="shortcuts" value="true" />\n);

    $body .= $self->_xmlpost();

    my $result = $self->_request(
        'method' => 'PUT',
        'url'    => $url,
        'body'   => $body
    ) || return( 0 );

    return( 1 );
}

sub disableShortcuts {
    my $self = shift;

    my ( $arg );
    %{$arg} = @_;

    map { $arg->{lc($_)} = $arg->{$_} } keys %{$arg};

    foreach my $param ( qw/ username / ) {
        $arg->{$param} || croak( "Missing required '$param' argument" );
    }

    my $url = qq(https://apps-apis.google.com/a/feeds/emailsettings/2.0/$self->{'domain'}/$arg->{'username'}/general);

    my ( $body );

    $body  = $self->_xmlpre();

    $body .= qq(  <apps:property name="shortcuts" value="false" />\n);

    $body .= $self->_xmlpost();

    my $result = $self->_request(
        'method' => 'PUT',
        'url'    => $url,
        'body'   => $body
    ) || return( 0 );

    return( 1 );
}



sub enableArrows {
    my $self = shift;

    my ( $arg );
    %{$arg} = @_;

    map { $arg->{lc($_)} = $arg->{$_} } keys %{$arg};

    foreach my $param ( qw/ username / ) {
        $arg->{$param} || croak( "Missing required '$param' argument" );
    }

    my $url = qq(https://apps-apis.google.com/a/feeds/emailsettings/2.0/$self->{'domain'}/$arg->{'username'}/general);

    my ( $body );

    $body  = $self->_xmlpre();

    $body .= qq(  <apps:property name="arrows" value="true" />\n);

    $body .= $self->_xmlpost();

    my $result = $self->_request(
        'method' => 'PUT',
        'url'    => $url,
        'body'   => $body
    ) || return( 0 );

    return( 1 );
}

sub disableArrows {
    my $self = shift;

    my ( $arg );
    %{$arg} = @_;

    map { $arg->{lc($_)} = $arg->{$_} } keys %{$arg};

    foreach my $param ( qw/ username / ) {
        $arg->{$param} || croak( "Missing required '$param' argument" );
    }

    my $url = qq(https://apps-apis.google.com/a/feeds/emailsettings/2.0/$self->{'domain'}/$arg->{'username'}/general);

    my ( $body );

    $body  = $self->_xmlpre();

    $body .= qq(  <apps:property name="arrows" value="false" />\n);

    $body .= $self->_xmlpost();

    my $result = $self->_request(
        'method' => 'PUT',
        'url'    => $url,
        'body'   => $body
    ) || return( 0 );

    return( 1 );
}



sub enableSnippets {
    my $self = shift;

    my ( $arg );
    %{$arg} = @_;

    map { $arg->{lc($_)} = $arg->{$_} } keys %{$arg};

    foreach my $param ( qw/ username / ) {
        $arg->{$param} || croak( "Missing required '$param' argument" );
    }

    my $url = qq(https://apps-apis.google.com/a/feeds/emailsettings/2.0/$self->{'domain'}/$arg->{'username'}/general);

    my ( $body );

    $body  = $self->_xmlpre();

    $body .= qq(  <apps:property name="snippets" value="true" />\n);

    $body .= $self->_xmlpost();

    my $result = $self->_request(
        'method' => 'PUT',
        'url'    => $url,
        'body'   => $body
    ) || return( 0 );

    return( 1 );
}

sub disableSnippets {
    my $self = shift;

    my ( $arg );
    %{$arg} = @_;

    map { $arg->{lc($_)} = $arg->{$_} } keys %{$arg};

    foreach my $param ( qw/ username / ) {
        $arg->{$param} || croak( "Missing required '$param' argument" );
    }

    my $url = qq(https://apps-apis.google.com/a/feeds/emailsettings/2.0/$self->{'domain'}/$arg->{'username'}/general);

    my ( $body );

    $body  = $self->_xmlpre();

    $body .= qq(  <apps:property name="snippets" value="false" />\n);

    $body .= $self->_xmlpost();

    my $result = $self->_request(
        'method' => 'PUT',
        'url'    => $url,
        'body'   => $body
    ) || return( 0 );

    return( 1 );
}



sub _request {
    my $self = shift;

    $self->{'token'}
    || croak qq(Authenticate first!);

    my ( $arg );
    %{$arg} = @_;

    my $request = HTTP::Request->new( $arg->{'method'} => $arg->{'url'} );

    $request->header( 'Content-Type'  => 'application/atom+xml' );
    $request->header( 'Authorization' => 'GoogleLogin auth=' . $self->{'token'} );

    if ( $arg->{'body'} ) {
        $request->header( 'Content-Length' => length( $arg->{'body'} ) );
        $request->content( $arg->{'body'} );
    }

    my $response = $self->{'lwp'}->request( $request );

    $response->is_success() || return( 0 );
    $response->content()    || return( 1 );

    return( $self->{'xml'}->XMLin( $response->content() ) );
}



sub _xmlpre {
    ( my $xml = << '    END' ) =~ s/^\s+//gm;
        <?xml version="1.0" encoding="UTF-8" ?>
        <atom:entry xmlns:atom="http://www.w3.org/2005/Atom" xmlns:apps="http://schemas.google.com/apps/2006">
    END

    return( $xml );
}

sub _xmlpost {
    ( my $xml = << '    END' ) =~ s/^\s+//gm;
        </atom:entry>
    END

    return( $xml );
}



1;

