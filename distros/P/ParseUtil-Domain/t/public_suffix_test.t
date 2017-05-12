#!/usr/bin/perl
# Modifed the tests provided by Mozilla
# %s/\/\//#/g
# %s/null/undef/g 

use lib qw{ ./t/lib blib/lib };
use Test::More tests => 48;
use ParseUtil::Domain ":parse";

sub checkPublicSuffix {
  my ( $host, $expected_domain ) = @_;
  if( $host =~ m/^\..*/ ) {
    # does not handle the leading dot case
    print "starts with dot\n";
    return;
  }

  my @parts =  split(/\./, $host ); 
  if( scalar @parts == 1 ) {
    is( undef, $expected_domain, "undef with only fragment" );
    # does not handle just passing in one fragment
    return;
  }

  my $results;
  eval { 
    $results = parse_domain( $host );
  };

  if( $@ ) {
    is( undef, $expected_domain, $@ );
  }
  else {
    my $tld = $results->{zone_ace};
    my @domain_parts = split(/\./, $results->{domain_ace} );
    if( scalar @domain_parts == 0 ) {
      #fail( "don't handle this case: " . $expected_domain);
      is( undef, $expected_domain, "matches tld" );
      return;
    }
    my $domain = pop( @domain_parts );
    is( "$domain.$tld", $expected_domain,  $host ); 
  
  }

}

# Any copyright is dedicated to the Public Domain.
# http:#creativecommons.org/publicdomain/zero/1.0/

# undef input.
#checkPublicSuffix(undef, undef);
# Mixed case.
checkPublicSuffix('COM', undef);
checkPublicSuffix('example.COM', 'example.com');
checkPublicSuffix('WwW.example.COM', 'example.com');
# Leading dot.
#checkPublicSuffix('.com', undef);
#checkPublicSuffix('.example', undef);
#checkPublicSuffix('.example.com', undef);
#checkPublicSuffix('.example.example', undef);
# Unlisted TLD.
checkPublicSuffix('example', undef);
#checkPublicSuffix('example.example', 'example.example');
#checkPublicSuffix('b.example.example', 'example.example');
#checkPublicSuffix('a.b.example.example', 'example.example');
# Listed, but non-Internet, TLD.
#checkPublicSuffix('local', undef);
#checkPublicSuffix('example.local', undef);
#checkPublicSuffix('b.example.local', undef);
#checkPublicSuffix('a.b.example.local', undef);
# TLD with only 1 rule.
checkPublicSuffix('biz', undef);
checkPublicSuffix('domain.biz', 'domain.biz');
checkPublicSuffix('b.domain.biz', 'domain.biz');
checkPublicSuffix('a.b.domain.biz', 'domain.biz');
# TLD with some 2-level rules.
checkPublicSuffix('com', undef);
checkPublicSuffix('example.com', 'example.com');
checkPublicSuffix('b.example.com', 'example.com');
checkPublicSuffix('a.b.example.com', 'example.com');
checkPublicSuffix('uk.com', undef);
checkPublicSuffix('example.uk.com', 'example.uk.com');
checkPublicSuffix('b.example.uk.com', 'example.uk.com');
checkPublicSuffix('a.b.example.uk.com', 'example.uk.com');
checkPublicSuffix('test.ac', 'test.ac');
# TLD with only 1 (wildcard) rule.
checkPublicSuffix('cy', undef);
checkPublicSuffix('c.cy', undef);
checkPublicSuffix('b.c.cy', 'b.c.cy');
checkPublicSuffix('a.b.c.cy', 'b.c.cy');
# More complex TLD.
checkPublicSuffix('jp', undef);
checkPublicSuffix('test.jp', 'test.jp');
checkPublicSuffix('www.test.jp', 'test.jp');
checkPublicSuffix('ac.jp', undef);
checkPublicSuffix('test.ac.jp', 'test.ac.jp');
checkPublicSuffix('www.test.ac.jp', 'test.ac.jp');
checkPublicSuffix('kyoto.jp', undef);
checkPublicSuffix('test.kyoto.jp', 'test.kyoto.jp');
checkPublicSuffix('ide.kyoto.jp', undef);
checkPublicSuffix('b.ide.kyoto.jp', 'b.ide.kyoto.jp');
checkPublicSuffix('a.b.ide.kyoto.jp', 'b.ide.kyoto.jp');
checkPublicSuffix('c.kobe.jp', undef);
checkPublicSuffix('b.c.kobe.jp', 'b.c.kobe.jp');
checkPublicSuffix('a.b.c.kobe.jp', 'b.c.kobe.jp');
checkPublicSuffix('city.kobe.jp', 'city.kobe.jp');
checkPublicSuffix('www.city.kobe.jp', 'city.kobe.jp');
# TLD with a wildcard rule and exceptions.
#checkPublicSuffix('om', undef);
#checkPublicSuffix('test.om', undef);
#checkPublicSuffix('b.test.om', 'b.test.om');
#checkPublicSuffix('a.b.test.om', 'b.test.om');
checkPublicSuffix('songfest.om', 'songfest.om');
checkPublicSuffix('www.songfest.om', 'songfest.om');
# US K12.
checkPublicSuffix('us', undef);
checkPublicSuffix('test.us', 'test.us');
checkPublicSuffix('www.test.us', 'test.us');
checkPublicSuffix('ak.us', undef);
checkPublicSuffix('test.ak.us', 'test.ak.us');
checkPublicSuffix('www.test.ak.us', 'test.ak.us');
checkPublicSuffix('k12.ak.us', undef);
checkPublicSuffix('test.k12.ak.us', 'test.k12.ak.us');
checkPublicSuffix('www.test.k12.ak.us', 'test.k12.ak.us');
