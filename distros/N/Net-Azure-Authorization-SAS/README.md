[![Build Status](https://travis-ci.org/ytnobody/p5-Net-Azure-Authorization-SAS.svg?branch=master)](https://travis-ci.org/ytnobody/p5-Net-Azure-Authorization-SAS)
# NAME

Net::Azure::Authorization::SAS - A Token Generator of Shared Access Signature Autorization for Microsoft Azure 

# SYNOPSIS

    use Net::Azure::Authorization::SAS;
    my $sas   = Net::Azure::Authorization::SAS->new(connection_string => 'Endpoint=sb://...');
    my $token = $sas->token('https://...');

# DESCRIPTION

Net::Azure::Authorization::SAS is a token generator class for Shared Access Signature (SAS).

If you want to know about SAS, please see [https://azure.microsoft.com/en-us/documentation/articles/storage-dotnet-shared-access-signature-part-1/](https://azure.microsoft.com/en-us/documentation/articles/storage-dotnet-shared-access-signature-part-1/) .

# METHODS

## new

    my $sas = Net::Azure::Autorization::SAS->new(conenction_string => 'Endpoint=sb://...');

The constructor method.

connection\_string parameter that is a "CONNECTION STRING" of "Access Policy" from azure portal is required. 

## token

    my $token = $sas->token($url);

Returns a token for set as "Authorization" header of a [HTTP::Request](https://metacpan.org/pod/HTTP::Request) object.

# LICENSE

Copyright (C) ytnobody.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

ytnobody <ytnobody@gmail.com>
