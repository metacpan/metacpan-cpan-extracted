#!/usr/bin/env perl

use utf8;
use 5.014;
use warnings;
use open qw/:encoding(UTF-8) :std/;

use Test::More;

BEGIN {
    if ( !$ENV{RELEASE_TESTING} ) {
        plan skip_all => 'Author tests not required for installation';
    }
    elsif ( !eval { require Net::Ping::External; Net::Ping::External->import('ping'); 1; } ) {
        plan skip_all => 'Net::Ping::External required for this test';
    }
}

BEGIN {
    use_ok( 'No::OrgNr', qw/domain2orgnr num_domains orgnr2domains/ );
}

if ( ping( host => 'whois.norid.no' ) ) {
    my $domain = 'uio.no';
    is( domain2orgnr($domain), '971035854', "Testing organization number for $domain" );

    $domain = 'google.no';
    is( domain2orgnr($domain), '988588261', "Testing organization number for $domain" );

    my $orgnr = '971035854';
    cmp_ok( num_domains($orgnr), '>=', '10', "Testing number of domains owned by $orgnr" );

    $orgnr = '988588261';
    cmp_ok( num_domains($orgnr), '>=', '10', "Testing number of domains owned by $orgnr" );

    is( num_domains('994039113'), 0, 'Organization number does not own a domain name' );

    my @domains = orgnr2domains('971035854');
    $domain = 'uio.no';
    my $num = grep { $_ eq $domain } @domains;
    is( $num, 1, "Testing domain name $domain" );

    @domains = orgnr2domains('988588261');
    $domain  = 'google.no';
    $num     = grep { $_ eq $domain } @domains;
    is( $num, 1, "Testing domain name $domain" );

    my @empty;
    is( orgnr2domains('994039113'), @empty, 'Organization number does not own a domain name' );
}

done_testing;
