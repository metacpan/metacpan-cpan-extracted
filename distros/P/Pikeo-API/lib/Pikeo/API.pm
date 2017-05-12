package Pikeo::API;

use warnings;
use strict;

use Data::Dumper;
use DateTime::Format::RSS;
use LWP::UserAgent;
use Digest::SHA1 qw(sha1_base64 sha1);
use Digest::MD5 qw(md5_hex);
use MIME::Base64;
use DateTime::Format::ISO8601;
use DateTime;
use Carp;

use XML::LibXML;
use XML::LibXML::XPathContext;

use Pikeo::API::User::Logged;

=head1 NAME

Pikeo::API - High-level OO interface to pikeo.com API!

=head1 VERSION

Version 1.01 

=cut

our $VERSION = '1.01';

=head1 SYNOPSIS

    use Pikeo::API;
    use Pikeo::API::Photos;

    # create an API object to maintain you session
    # trough out the diferent calls
    my $api = Pikeo::API->new({api_secret=>'asd', api_key=>'asdas'});
    
    # Create the Photos facade
    my $photos = Pikeo::API::Photos->new({ api => $api });
    # Search for photos
    $photos_searched = $photos->search({text=>'shozu'});

=head1 DESCRIPTION

This package provides a OO interface to the pikeo.com API.

Using the pikeo REST API, this distribution provides an high-level
interface to traverse the pikeo objects.

To use this module you need to have a valid API key.

This module, Pikeo::API, provides the object that olds the 
api request definitions such as api_key, user agent configuration
and credentials for de authenticaded calls.

You must instantiate a Pikeo::API object in order to use the facade
module that abstract the photos, albums, etc.

All the facade modules receive an Pikeo::API object as a mandatory argument
for their constructors.

=head2 FACADE MODULES

=over 4

=item Pikeo::API::Photos   

Search and retrieve photos.

=item Pikeo::API::User

Search and retrieve users/profiles.

=item Pikeo::API::User::Logged

Provides access to the private methods for your user.
You must be logged in.

=back

=head1 FUNCTIONS

=head2 CONSTRUCTORS

=head3 new( \%args )

Returns a Pikeo::API object.

Required args are:

=over 4

=item * api_key

Your api key

=item * api_secret

Optional args are:

=item * username

Username to login

=item * password

Password for the logged user

=back

=cut

sub new {
   my $class = shift;
   my $params= shift;

   croak "I need an API key" unless $params->{'api_key'};
   croak "I need an API shared secret" unless $params->{'api_secret'};

   my $self = {
    _api_key    => $params->{'api_key'},
    _api_secret => $params->{'api_secret'},
   };

   $self = bless $self, $class;

   if ( $params->{'username'} ) {
     $self->login({$params->{'username'}, $params->{'password'}});
   }
   return $self;
}

=head2 INSTANCE METHODS

=head3 login(\%args)

Authenticate and logs in a user.

Required args are:

=over 4

=item * username

Username to login

=item * password

=back

=cut

sub login {
    my $self   = shift;
    my $params = shift;

    croak "need a username and password" 
        unless $params->{'username'} and $params->{'password'};

    $self->{_auth_user} = $params->{'username'};
    $self->{_auth_pass} = $params->{'password'};

    #TODO make a test call to login to validate user and password

    return 1;
}

=head3 is_logged_in()

Returns 1 if there is a logged access, 0 otherwise

=cut
 
sub is_logged_in {
    my $self = shift;
    return $self->{_auth_user} ? 1 : 0;
}

=head3 request_parsed($api_method, \%args)

Make a request to the give API method and returns a XML::LibXML object with the result.

\%args should contain all the arguments to be passed as parameters to the remote API.

=cut

sub request_parsed {
    my $self   = shift;
    my $api    = shift;
    my $params = shift;

    my $resp = $self->request( $api, $params );
    croak "request failed ".$resp->status_line unless $resp->is_success;

    my $parser = XML::LibXML->new();
    my $doc = XML::LibXML::XPathContext->new($parser->parse_string($resp->content));

    if ( $doc->findvalue("/response/fault/fault_code") ) {
        croak "API error code ".$doc->findvalue("/response/fault/fault_code").
              " ( ".$doc->findvalue("/response/fault/fault_message")." )";
    }

    return $doc;
}

sub request {
    my $self   = shift;
    my $api    = shift;
    my $params = shift;

    my $iso8601 = DateTime::Format::ISO8601->new;
    my $a = LWP::UserAgent->new(timeout=>20);
    my $timestamp = DateTime->now()."Z";
    my $nonce = encode_base64($timestamp.rand(10).rand(10));
    chomp($nonce);

    my $api_sig_raw = $nonce.$timestamp.$self->{_api_secret};
    if ( $self->{_auth_user} ) {
        $api_sig_raw .= uc(md5_hex($self->{_auth_pass}));
        $params->{login} = $self->{_auth_user};
    }
    my $api_sig = encode_base64(sha1($api_sig_raw));
    chomp($api_sig);

    my $r = $a->post( 'http://api.pikeo.com/services/pikeo/v2/rest',
                   {
                    nonce     => $nonce,
                    api_key   => $self->{_api_key},
                    api_sig   => $api_sig,
                    timestamp => $timestamp,
                    method    => $api,
                    %$params,
                   }
                 );

   return $r;
}

=head1 AUTHOR

Bruno Tavares, C<< <bmavt at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-pikeo-api at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Pikeo-API>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Pikeo::API

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Pikeo-API>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Pikeo-API>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Pikeo-API>

=item * Search CPAN

L<http://search.cpan.org/dist/Pikeo-API>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2008 Bruno Tavares, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Pikeo::API
