#!/usr/bin/env perl

use strict;
use warnings;

# Using Paws only to resolve the current AWS credentials.
use Paws;
use Paws::Credential::ProviderChain;

use Signer::AWSv4::S3;

my $creds = Paws::Credential::ProviderChain->new;

my $region = $ARGV[0];
my $bucket = $ARGV[1];
my $key = $ARGV[2];

my $signer = Signer::AWSv4::S3->new(
  access_key => $creds->access_key,
  secret_key => $creds->secret_key,
  region => $region,
  bucket => $bucket,
  key => $key,
  expires => 3600,
  method => 'GET',
);

print $signer->signed_url;

