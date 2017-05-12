package Net::Surveymonkey;
{
  $Net::Surveymonkey::VERSION = '0.03';
}

# $Id: Surveymonkey.pm 5312 2015-01-19 06:05:03Z liosha $

# ABSTRACT: Surveymonkey API client


use 5.010;
use strict;
use warnings;
use utf8;

use Mouse;

use Carp;
use JSON;
use LWP::UserAgent;
use Log::Any '$log';
use File::Slurp;
use List::Util qw/first/;


our $SM_API_URL ||= 'https://api.surveymonkey.net/v2';
our $SM_API_KEY;
our $SM_API_KEY_FILE;
our $SM_API_TOKEN;
our $SM_API_TOKEN_FILE;


has key => (
    is => 'rw',
    isa => 'Str',
    lazy_build => 1,
    clearer => '_clear_key',
);


has key_file => (
    is => 'rw',
    isa => 'Str',
    trigger => sub { shift()->_clear_key() } ,
);

sub _build_key {
    my ($self) = @_;

    if ( my $file = $self->key_file || $SM_API_KEY_FILE ) {
        return $self->_get_key_from_file($file);
    }

    return $SM_API_KEY;
}



has token => (
    is => 'rw',
    isa => 'Str',
    lazy_build => 1,
    clearer => '_clear_token',
);



has token_file => (
    is => 'rw',
    isa => 'Str',
    trigger => sub { shift()->_clear_token() } ,
);


sub _build_token {
    my ($self) = @_;

    if ( my $file = $self->token_file || $SM_API_TOKEN_FILE ) {
        return $self->_get_key_from_file($file);
    }

    return $SM_API_TOKEN;
}

sub _get_key_from_file {
    my ($self, $file) = @_;

    # first non-empty not commented string
    my $str = first {/^[^#]/} map {s/\s+$//r} map {s/^\s+//r} split /\n/x, read_file $file;
    return $str;
}








our %METHOD_ALIAS = (
    create_flow         => 'batch/create_flow',
    get_survey_list     => 'surveys/get_survey_list',
    get_survey_details  => 'surveys/get_survey_details',
    get_collector_list  => 'surveys/get_collector_list',
    create_collector    => 'collectors/create_collector',
    get_respondent_list => 'surveys/get_respondent_list',
    get_responses       => 'surveys/get_responses',
    get_response_counts => 'surveys/get_response_counts',
    get_user_details    => 'user/get_user_details',
    get_template_list   => 'templates/get_template_list',
    send_flow           => 'batch/send_flow',
);



sub call
{
    my ($self, $method => $data) = @_;

    $method = $METHOD_ALIAS{$method} || $method;

    my $url = "$SM_API_URL/$method?api_key=" . $self->key();
    my $payload = encode_json $data;

    my %header = (
        "Authorization" => "bearer " . $self->token(),
        "Content-Type"  => "application/json",
    );

    $log->trace("Call: $method $payload")  if $log->is_trace();
    my $response = LWP::UserAgent->new()->post($url, %header, Content => $payload);
    my $resp_content = $response->decoded_content();
    $log->trace("Response: $resp_content")  if $log->is_trace();

    my $result = decode_json $resp_content;

    croak "SM API call failed: $result->{errmsg}"  if $result->{status};

    return $result->{data};
}




while (my ($alias, $sm_method) = each %METHOD_ALIAS) {
    my $sub = sub {
        my $self = shift;
        return $self->call( $sm_method => @_);
    };
    __PACKAGE__->meta->add_method($alias => $sub);
}

__PACKAGE__->meta->make_immutable();

1;

__END__
=pod

=head1 NAME

Net::Surveymonkey - Surveymonkey API client

=head1 VERSION

version 0.03

=head1 SYNOPSIS

    # provide your api-key and oauth-token 
    my $sm_api = Net::Surveymonkey->new( key => $key, token => $token );

    my $surveys = $sm_api->get_survey_list();

=head1 DESCRIPTION

Client for Surveymonkey web api.

API methods are mapped to object methods.

See api docs for parameters and response formats at https://developer.surveymonkey.com/

=head1 ATTRIBUTES

=head2 key

Application API key.

Can be provided directly or got from key file.

Default is in $Net::Surveymonkey::SM_API_KEY

=head2 key_file

File where key shoutd be taken from.

Default is in $Net::Surveymonkey::SM_API_KEY_FILE

=head2 token

Application-to-account access key.

Can be provided directly or got from file.

Default is in $Net::Surveymonkey::SM_API_TOKEN

=head2 token_file

File where token shoutd be taken from.

Default is in $Net::Surveymonkey::SM_API_TOKEN_FILE

=head1 METHODS

=head2 new

    my $api = Net::Surveymonkey->new( key => $key, token => $token );
    
    # or 

    my $api = Net::Surveymonkey->new( key_file => '/path/to/key', token_file => '/path/to/token/ );

    # or indirectly

    $Net::Surveymonkey::SM_API_KEY = $key;
    $Net::Surveymonkey::SM_API_TOKEN = $token;

    my $api = Net::Surveymonkey->new();

Constructor

=head2 call

    my $result = $api->call($method => $params);

API method call. Dies on errors

=head2 create_flow         => 'batch/create_flow'

=head2 get_survey_list     => 'surveys/get_survey_list'

=head2 get_survey_details  => 'surveys/get_survey_details'

=head2 get_collector_list  => 'surveys/get_collector_list'

=head2 create_collector    => 'collectors/create_collector'

=head2 get_respondent_list => 'surveys/get_respondent_list'

=head2 get_responses       => 'surveys/get_responses'

=head2 get_response_counts => 'surveys/get_response_counts'

=head2 get_user_details    => 'user/get_user_details'

=head2 get_template_list   => 'templates/get_template_list'

=head2 send_flow           => 'batch/send_flow'

=head1 AUTHOR

liosha <liosha@yandex-tean.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Yandex LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

