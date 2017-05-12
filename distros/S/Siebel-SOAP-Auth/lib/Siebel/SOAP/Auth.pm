package Siebel::SOAP::Auth;

use strict;
use warnings;
use Moo 2.000001;
use Types::Standard 1.000005 qw(Str Int RegexpRef Num);
use XML::LibXML 2.0115;
use namespace::clean 0.25;
use Encode qw(encode);
use Scalar::Util qw(blessed);
use Time::HiRes qw(time);
use Log::Report 1.05 'siebel-soap-auth', syntax => 'SHORT';
use Carp;
our $VERSION = '0.004'; # VERSION

=pod

=head1 NAME

Siebel::SOAP::Auth - Moo based class to implement transparent Siebel Session Management for XML::Compile::WSDL11

=head1 SYNOPSIS

    use XML::Compile::WSDL11;
    use XML::Compile::SOAP11;
    use XML::Compile::Transport::SOAPHTTP;
    use Siebel::SOAP::Auth;

    my $wsdlfile = File::Spec->catfile( 't', 'SWIContactServices.WSDL' );
    my %request = (
        ListOfSwicontactio => {
            Contact =>
                { Id => '0-1', FirstName => 'Siebel', LastName => 'Administrator' }
        }
    );

    my $wsdl = XML::Compile::WSDL11->new($wsdlfile);
    my $auth = Siebel::SOAP::Auth->new(
        {
            user          => 'sadmin',
            password      => 'XXXXXXX',
            token_timeout => MAGIC_NUMBER,
            remain_ttl    => 0
        }
    );

    my $call = $wsdl->compileClient(
        operation      => 'SWIContactServicesQueryByExample',
        transport_hook => sub { 
            my ( $request, $trace, $transporter ) = @_;
            # request was modified
            my $new_request = $auth->add_auth_header($request);
            return $trace->{user_agent}->request($new_request);
        }
    );

    my ( $answer, $trace ) = $call->(%request);

    if ( my $e = $@->wasFatal ) {

        $e->throw;

    } else {

        # do something with the answer

    }

=head1 DESCRIPTION

Siebel::SOAP::Auth provides authentication for Oracle's Siebel inbound web services by implementing Session Management.

Implementation uses a instance of Siebel::SOAP::Auth inside a C<transport_hook> C<sub>, passing to it the original request. The original request will
be modified, adding necessary authentication data to the SOAP Header. The instance of Siebel::SOAP::Auth will also try to manage the session and token expiration times and
request a new one before expiration, avoiding a new round-trip to the server for another successful request.

Session Management for calling Siebel web services great improves speed, since regular authentication takes a loot of additional steps. This class will implement the management
of requesting tokens automatically (but some tuning with the parameters might be necessary).

This class is tight coupled to L<XML::Compile::WSDL11> interface. By using it, it is expected that you will use everything else from L<XML::Compile>.

This class is L<Moo> based and it uses also L<Log::Report> to provide debug information if required.

=head1 ATTRIBUTES

The following attributes are available:

=head2 token_key

A string of the respective key of the token value after response from the Siebel Server is converted to a hash by L<XML::Compile::WSDL11>.

By default, it is defined as C<'{' . $self->get_header_ns() . '}SessionToken'>.

This is a lazy attribute, as defined by L<Moo>.

=cut

has token_key => ( is => 'lazy', isa => Str, reader => 'get_token_key' );

=head2 header_ns

A string that represents the SOAP Header namespace.

By default it is C<http://siebel.com/webservices>. You might want to change it depending
on the WSDL (current this is not done automatically).

This is a read/write attribute.

=cut

has header_ns => (
    is      => 'rw',
    isa     => Str,
    default => 'http://siebel.com/webservices',
    reader  => 'get_header_ns',
    writer  => 'set_header_ns'
);

=head2 user

A string representing the login to be used for web service authentication.

This is a required attribute during object creation.

=cut

has user => (
    is       => 'rw',
    isa      => Str,
    reader   => 'get_user',
    writer   => 'set_user',
    required => 1
);

=head2 password

A string representing the login password used for authentication.

This is a required attribute during object creation.

=cut

has password => (
    is       => 'rw',
    isa      => Str,
    reader   => 'get_pass',
    writer   => 'set_pass',
    required => 1
);

=head2 token

A string type attribute that holds the token.

All token details are handled internally.

=cut

has token => (
    is      => 'ro',
    isa     => Str,
    reader  => 'get_token',
    writer  => '_set_token',
    default => 'unset'
);

=head2 lookup_ns

A string type attribute that holds the namespace that must be used to find
the namespace prefix that should be used to declare the elements for authentication
in the SOAP header.

By default is set to C<http://schemas.xmlsoap.org/soap/envelope/>.

This is a read/write attribute.

=cut

has lookup_ns => (
    is      => 'rw',
    isa     => Str,
    default => 'http://schemas.xmlsoap.org/soap/envelope/',
    reader  => 'get_lookup_ns',
    writer  => 'set_lookup_ns'
);

=head2 remain_ttl

A integer that defines the minimum amount of remaining seconds the token should have before asking
for a new one.

By default it is set to 10 seconds, but you might want to fine tune it depending on several factor, specially
the average time the request to a web services takes to have an answer.

This is a read-only attribute, so you must set it's value during object creation.

=cut

has remain_ttl =>
  ( is => 'ro', isa => Int, default => 10, reader => 'get_remain_ttl' );

=head2 session_type

A string type attribute that defines the session type to be used.

By default it is set to C<Stateless>.

This is a read-only attribute, so you must set it's value during object creation.

=cut

has session_type => (
    is      => 'ro',
    isa     => Str,
    reader  => 'get_session_type',
    default => 'Stateless'
);

=head2 last_fault

A string attribute type that holds the error message received from the Siebel Server.

This is a read-only attribute.

=cut

has last_fault => (
    is     => 'ro',
    isa    => Str,
    reader => 'get_last_fault',
    writer => '_set_last_fault'
);

=head2 auth_fault

A compiled regular expression that is used to match specific SOAP faults returned by the Siebel Server
that means "token expired".

It is set by default to C</^Error\sCode:\s10944642/>.

=cut

has auth_fault => (
    is      => 'ro',
    isa     => RegexpRef,
    reader  => 'get_auth_fault',
    default => sub { qr/^Error\sCode:\s10944642/ }
);

=head2 session_timeout

A integer type attribute that defines the Session Timeout to be considered, as defined on the Siebel Server.

By default is set to 900 seconds.

This is a read-only attribute.

=cut

has session_timeout =>
  ( is => 'ro', isa => Int, default => 900, reader => 'get_session_timeout' );

=head2 token_timeout

A integer type attribute that defines the Token Timeout to be considered, as defined on the Siebel Server.

By default is set to 900 seconds.

This is a read-only attribute.

=cut

has token_timeout =>
  ( is => 'ro', isa => Int, default => 900, reader => 'get_token_timeout' );

=head2 token_max_age

A integer type attribute that defines the Token Maximum Age to be considered, as defined on the Siebel Server.

By default is set to 172800 seconds.

This is a read-only attribute.

=cut

has token_max_age =>
  ( is => 'ro', isa => Int, default => 172800, reader => 'get_token_max_age' )
  ;    # 2880 minutes

has _token_birth => (
    is        => 'ro',
    isa       => Num,
    reader    => '_get_token_birth',
    writer    => '_set_token_birth',
    predicate => 1,
    clearer   => 1
);

=head1 METHODS

All attributes have their respectiver getters and setters as defined in the Perl Best Practices book.

Of course, read-only attributes have only getters.

This is the list of those methods with a brief explanation:

=head2 get_token_key

Getter for the C<token_key> attribute.

=head2 get_header_ns

Getter for the C<header_ns> attribute.

=head2 set_header_ns

Setter for the C<header_ns> attribute.

=head2 get_user

Getter for the C<user> attribute.

=head2 set_user

Setter for the C<user> attribute.

=head2 get_pass

Getter for the C<password> attribute.

=head2 set_pass

Setter for the C<password> attribute.

=head2 get_token

Getter for the C<token> attribute.

=head2 get_lookup_ns

Getter for the C<lookup_ns> attribute.

=head2 get_remain_ttl

Getter for the C<remain_ttl> attribute.

=head2 get_session_type

Getter for the C<session_type> attribute.

=head2 get_session_timeout

Getter for the C<session_timeout> attribute.

=head2 get_token_timeout

Getter for the C<token_timeout> attribute.

=head2 get_token_max_age

Getter for the C<token_max_age> attribute.

=head2 get_auth_fault

Getter for the C<auth_fault> attribute.

=head2 get_last_fault

Getter for the C<last_fault> attribute.

=cut

sub _build_token_key {

    my ($self) = @_;
    return '{' . $self->get_header_ns() . '}SessionToken';

}

=head2 add_auth_header

This method B<must> be invoked inside the C<transport_hook> parameter definition during the call to C<compileClient> method
of L<XML::Compile::WSDL11>.

It expects as parameter the original L<HTTP::Request> object, that will have its payload modified (SOAP Header).

It returns the L<HTTP::Request> with its payload modified.

=cut

sub add_auth_header {

    my ( $self, $request ) = @_;

    croak "Expect as parameter a HTTP::Request instance"
      unless ( ( defined($request) )
        and ( defined( blessed($request) ) )
        and ( $request->isa('HTTP::Request') ) );

    my $payload = XML::LibXML->load_xml( string => $request->decoded_content );
    my $root    = $payload->getDocumentElement;
    my $prefix  = $root->lookupNamespacePrefix( $self->get_lookup_ns() );
    my $soap_header = $payload->createElement( $prefix . ':Header' );
    my %auth;

    if ( $self->get_token() ne 'unset' ) {

# how long the token is around plus the acceptable remaining seconds to be reused
        my $token_age =
          time() - $self->_get_token_birth() + $self->get_remain_ttl();
        trace "token age is $token_age";

        if (    ( $token_age < $self->get_token_max_age() )
            and ( $token_age < $self->get_session_timeout() )
            and ( $token_age < $self->get_token_timeout() ) )
        {

            %auth = (
                SessionToken => $self->get_token(),
                SessionType  => $self->get_session_type()
            );
            trace 'using acquired session token';

        }
        else {

            trace 'preparing to request a new session token';
            %auth = (
                SessionType   => $self->get_session_type(),
                UsernameToken => $self->get_user(),
                PasswordText  => $self->get_pass()
            );
            $self->_set_token('unset');    # sane setting
            $self->_clear_token_birth();
            trace 'cleaned up token and token_birth attributes';

        }

    }
    else {

        %auth = (
            SessionType   => $self->get_session_type(),
            UsernameToken => $self->get_user(),
            PasswordText  => $self->get_pass()
        );

    }

    my $ns = $self->get_header_ns();

    # WORKAROUND: sort is used to make it easier to test the request assembly
    foreach my $element_name ( sort( keys(%auth) ) ) {

        my $child = $payload->createElementNS( $ns, $element_name );
        $child->appendText( $auth{$element_name} );
        $soap_header->appendChild($child);

    }

    $root->insertBefore( $soap_header, $root->firstChild );

    my $new_content = encode( 'UTF-8', $root );
    $request->header( Content_Length => length($new_content) );
    $request->content($new_content);
    return $request;

}

=head2 find_token

Finds and set the token returned by the Siebel Server in the response of a request.

It expects as parameter the hash reference returned by the execution of the code reference created by the
C<compileClient> method of L<XML::Compile::WSDL11>. This hash reference must have a key as defined by the
C<token_key> attribute of a instance of Siebel::SOAP::Auth.

The method also will invoke C<check_fault> automatically to validate the answer.

Once the token is found, the object updates itself internally. Otherwise an exception will be raised.

=cut

sub find_token {

    my ( $self, $answer ) = @_;

    croak "Expect as parameter a hash reference"
      unless ( ( defined($answer) ) and ( ref($answer) eq 'HASH' ) );

    $self->check_fault($answer);
    my $key = $self->get_token_key();

    if ( exists( $answer->{$key} ) ) {

        croak "Expect as parameter a XML::LibXML::Element instance"
          unless ( ( defined( $answer->{$key} ) )
            and ( defined( blessed( $answer->{$key} ) ) )
            and ( $answer->{$key}->isa('XML::LibXML::Element') ) );

        $self->_set_token( $answer->{$key}->textContent );
        $self->_set_token_birth( time() ) unless ( $self->_has_token_birth );
        return 1;

    }
    else {

        croak "could not find the key $key in the answer received as parameter";

    }

}

=head2 check_fault

Verifies if an answer from the Siebel Server is a failure of not.

Expects as parameter the answer.

If the fault returned by the server is related to a token expiration, a exception
will be raised with the text "token expired".

That means you should check for this exception with the C<try> function of L<Log::Report> and
provide a fallback routine (like resending your request). The instance of Siebel::SOAP::Auth will
also resets the token status internally to allow reuse.

For other errors, an exception will be created with exactly the same message available in the fault
element of the SOAP envelope. You should evaluate the error message and take appropriate measures.

=cut

sub check_fault {

    my ( $self, $answer ) = @_;

    if ( exists( $answer->{Fault} ) ) {

        $self->_set_token('unset');    # sane setting
        $self->_clear_token_birth();
        trace 'cleaned up token and token_birth attributes';
        if ( $answer->{Fault}->{faultstring} =~ $self->get_auth_fault() ) {

            croak 'token expired';

        }
        else {

            croak $answer->{Fault}->{faultstring};

        }

    }

}

=head1 DEBUGGING

You can enable debug messages for your code in the same way it is possible for L<XML::Compile::WSDL11>: by using L<Log::Report>. For example, the line:

    use Log::Report mode => 'DEBUG';

Added to your code will print trace messages of Siebel::SOAP::Auth object.

To disable just change the line to:

    use Log::Report mode => 'NORMAL';

=head1 SEE ALSO

=over

=item *

L<XML::Compile::WSDL11>

=item *

L<Log::Report>

=item *

L<Moo>

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 of Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

This file is part of Siebel-SOAP-Auth distribution.

Siebel-SOAP-Auth is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Siebel-SOAP-Auth is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Term-YAP. If not, see <http://www.gnu.org/licenses/>.

=cut

1;
