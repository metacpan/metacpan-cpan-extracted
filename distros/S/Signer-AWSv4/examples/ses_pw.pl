#!/usr/bin/env perl

use v5.10;
use Paws;
use Paws::Credential::ProviderChain;
use Signer::AWSv4::SES;

my $creds = Paws::Credential::ProviderChain->new;

say $creds->access_key;

my $signer = Signer::AWSv4::SES->new(
  access_key => $creds->access_key,
  secret_key => $creds->secret_key,
  region => 'eu-west-1',
);

say $signer->smtp_password;
