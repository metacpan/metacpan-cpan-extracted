package Net::Azure::Authorization::SAS;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.02";
our $DEFAULT_TOKEN_EXPIRE = 3600;

use Carp;
use URI;
use URI::Escape 'uri_escape';
use Digest::SHA 'hmac_sha256';
use MIME::Base64 'encode_base64';
use String::CamelCase 'decamelize';
use Class::Accessor::Lite (
    new => 0,
    ro  => [qw[
        connection_string 
        endpoint 
        shared_access_key_name 
        shared_access_key 
        expire
    ]],
);

sub new {
    my ($class, %param) = @_;
    croak 'connection_string is required' if !defined $param{connection_string};
    $param{expire}  ||= $DEFAULT_TOKEN_EXPIRE;
    %param = (%param, $class->_parse_connection_string($param{connection_string}));
    bless {%param}, $class;
}

sub _parse_connection_string {
    my ($class, $string) = @_;
    my %parsed = (map {split '=', $_, 2} split(';', $string));
    ( map {(decamelize($_) => $parsed{$_})} keys %parsed ); 
}

sub token {
    my ($self, $url) = @_;
    croak 'An url for token is required' if !defined $url;
    my $uri         = URI->new($url);
    my $target_uri  = lc(uri_escape(lc(sprintf("%s://%s%s", $uri->scheme, $uri->host, $uri->path))));
    my $expire_time = time + $self->expire;
    my $to_sign     = "$target_uri\n$expire_time";
    my $signature   = encode_base64(hmac_sha256($to_sign, $self->shared_access_key));
    chomp $signature;
    sprintf 'SharedAccessSignature sr=%s&sig=%s&se=%s&skn=%s', $target_uri, uri_escape($signature), $expire_time, $self->shared_access_key_name;
}

1;
__END__

=encoding utf-8

=head1 NAME

Net::Azure::Authorization::SAS - A Token Generator of Shared Access Signature Autorization for Microsoft Azure 

=head1 SYNOPSIS

    use Net::Azure::Authorization::SAS;
    my $sas   = Net::Azure::Authorization::SAS->new(connection_string => 'Endpoint=sb://...');
    my $token = $sas->token('https://...');


=head1 DESCRIPTION

Net::Azure::Authorization::SAS is a token generator class for Shared Access Signature (SAS).

If you want to know about SAS, please see L<https://azure.microsoft.com/en-us/documentation/articles/storage-dotnet-shared-access-signature-part-1/> .


=head1 METHODS

=head2 new

    my $sas = Net::Azure::Autorization::SAS->new(conenction_string => 'Endpoint=sb://...');

The constructor method.

connection_string parameter that is a "CONNECTION STRING" of "Access Policy" from azure portal is required. 

=head2 token

    my $token = $sas->token($url);

Returns a token for set as "Authorization" header of a L<HTTP::Request> object.

=head1 LICENSE

Copyright (C) ytnobody.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

ytnobody E<lt>ytnobody@gmail.comE<gt>

=cut

