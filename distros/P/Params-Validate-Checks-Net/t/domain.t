#! /usr/bin/perl
#
# tests Params::Validate::Checks::Net domain check does what's required

use warnings;
use strict;

use Test::More tests => 6;
use Test::Exception;


BEGIN
{
  use_ok 'Params::Validate::Checks', qw<validate as>
      or die "Loading Params::Validate::Checks failed";
  use_ok 'Params::Validate::Checks::Net'
      or die "Loading Params::Validate::Checks failed";
};

sub site
{
  my %arg = validate @_, {domain => {as 'domain'}};

  "www.$arg{domain}";
}

lives_and { is site(domain => 'theregister.co.uk'), 'www.theregister.co.uk' }
    'allows valid domain name';

throws_ok { site(domain => 'sleepy.zz') }
    qr/did not pass the 'domain' callback/,
    'complains at unrecognized TLD';

throws_ok { site(domain => 'staging') }
    qr/did not pass the 'domain' callback/,
    'complains at unqualified hostname';

throws_ok { site(domain => 'http://www.beccyowen.com/') }
    qr/did not pass the 'domain' callback/,
    'complains at URL (including scheme)';
