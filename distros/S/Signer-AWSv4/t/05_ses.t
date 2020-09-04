#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Signer::AWSv4::SES;

{
  my $signer = Signer::AWSv4::SES->new(
    access_key => 'AKIAIOSFODNN7EXAMPLE',
    secret_key => 'SECRET_KEY',
    region => 'eu-west-1',
  );

  cmp_ok($signer->smtp_user, 'eq', 'AKIAIOSFODNN7EXAMPLE');
  cmp_ok($signer->smtp_password, 'eq', 'BIhFZ/Ylx0jPVY7JeKUnHT4rO9jfB1VuZu4qglc/3gj9');
  cmp_ok($signer->smtp_endpoint, 'eq', 'email-smtp.eu-west-1.amazonaws.com');
}

{
  my $signer = Signer::AWSv4::SES->new(
    access_key => 'AKIAIOSFODNN7EXAMPLE',
    secret_key => 'SECRET_KEY',
    region => 'us-east-1',
  );

  cmp_ok($signer->smtp_user, 'eq', 'AKIAIOSFODNN7EXAMPLE');
  cmp_ok($signer->smtp_password, 'eq', 'BEhllZN9mAOanokSKCZhFUnAZr05oZGH3Yga8SI+ujh+');
  cmp_ok($signer->smtp_endpoint, 'eq', 'email-smtp.us-east-1.amazonaws.com');
}


{
  my $signer = Signer::AWSv4::SES->new(
    access_key => 'AKIAIOSFODNN7EXAMPLE',
    secret_key => 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY',
    region => 'dummy',
  );

  cmp_ok($signer->smtp_user, 'eq', 'AKIAIOSFODNN7EXAMPLE');
  cmp_ok($signer->smtp_password_v2, 'eq', 'An60U4ZD3sd4fg+FvXUjayOipTt8LO4rUUmhpdX6ctDy');
}

done_testing;
