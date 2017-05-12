package Net::AWS::SES::Response;

=head1 NAME

Net::AWS::SES::Response - Perl class that represents a response from AWS SES

=head1 SYNPOSIS

    # see Net::AWS::SES

=head1 DESCRIPTION

This class is not meant to be used directly, but through L<Net::AWS::SES|Net::AWS::SES>. First you should be familiar with L<Net::AWS::SES|Net::AWS::SES> and only then come back to this class for new information

=head1 METHODS

=cut

use strict;
use warnings;
use Carp ('croak');
use XML::Simple;

our $VERSION = '0.03';

sub new {
    my $class = shift;
    my ( $response, $action ) = @_;

    unless ( $response
        && ref($response)
        && $response->isa("HTTP::Response")
        && $action )
    {
        croak "new(): usage error";
    }
    my $self = bless { __response => $response, data => {}, action => $action },
      $class;
    $self->__parse_response;
    return $self;
}

sub __parse_response {
    my $self = shift;
    $self->{data} = XMLin(
        $self->raw_content,
        GroupTags => {
            Identities => 'member',
            DkimTokens => 'member'
        },
        KeepRoot   => 0,
        ForceArray => [ 'member', 'DkimAttributes' ]
    );
}

=head2 message_id()

Returns a message id for successfully sent e-mails. Only valid for successful requests.

=cut

sub message_id {
    my $self   = shift;
    my $action = $self->{action};
    return unless $self->result;
    return $self->result->{'MessageId'};
}

=head2 result()

Returns parsed contents of the response. This is usually the contents of C<*Result> element. Exception is the error response, in which case it returns the ontents of C<Error> element.

=cut

sub result {
    my $self   = shift;
    my $action = $self->{action};
    if ( $self->is_error ) {
        return $self->{data};    # error response do not have *Result containers
    }
    return $self->{data}->{ $action . 'Result' };
}

=head2 result_as_json()

Same as C<result()>, except converts the data into JSON notation

=cut

sub result_as_json {
    my $self = shift;
    require JSON;
    return JSON::to_json( $self->result, { pretty => 1 } );
}

=head2 raw_content()

This is the raw (unparsed) by decoded HTTP content as returned from the AWS SES. Usually you do not need it. If you think you need it just knock yourself out!

=cut

sub raw_content {
    return $_[0]->{__response}->decoded_content;
}

=head2 is_success()

=head2 is_error()

This is the first thing you should check after each request().

=cut

sub is_success {
    return $_[0]->{__response}->is_success;
}

sub is_error {
    return $_[0]->{__response}->is_error;
}

=head2 http_code()

Since all the api request/response happens using HTTP Query actions, this code returns the HTTP response code. For all successfull response it returns C<200>, errors usually return C<400>. This is here just in case

=cut

sub http_code {
    return $_[0]->{__response}->code;
}

=head2 error_code()

Returns an error code from AWS SES. Unlik C<http_code()>, this is a short error message, as documented in AWS SES API reference

=cut

=head2 error_message()

Returns more descriptive error message from AWS SES

=head2 error_type()

Returns the type of the error. Most of the time in my experience it returns C<Sender>.

=cut

sub error_code {
    my $self = shift;
    return $self->{data}->{Error}->{Code};
}

sub error_message {
    my $self = shift;
    return $self->{data}->{Error}->{Message};
}

sub error_type {
    my $self = shift;
    return $self->{data}->{Error}->{Type};
}

=head2 request_id()

Returns an ID of the request. All response, including the ones resulting in error, contain a RequestId.

=cut

sub request_id {
    my $self = shift;
    return $self->{data}->{RequestId} if $self->{data}->{RequestId};
    my $action = $self->{action};
    return $self->{data}->{'ResponseMetadata'}->{RequestId};
}

=head2 dkim_attributes()

The same as

    $response->result->{DkimAttributes}

Only meaning for get_dkim_attributes() api call

=cut

sub dkim_attributes {
    my $self = shift;
    if ( my $attributes = $self->result->{DkimAttributes}->[0]->{entry} ) {
        return $self->result->{DkimAttributes};
    }
    return;
}

=head1 SEE ALSO

L<Net::AWS::SES|Net::AWS::SES>

=head1 AUTHOR

Sherzod B. Ruzmetov E<lt>sherzodr@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by L<Talibro LLC|https://www.talibro.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
