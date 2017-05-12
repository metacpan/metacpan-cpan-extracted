#!/usr/bin/perl

use Test::More 'no_plan';
BEGIN { use_ok('Net::LDAP::FilterBuilder') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $f = Net::LDAP::FilterBuilder->new( sn => 'Gorwits' );
is( "$f", '(sn=Gorwits)' );

$f = Net::LDAP::FilterBuilder->new( sn => [ 'Gorwits', 'Edwards', 'Morrell' ] );
is( "$f", '(|(sn=Gorwits)(sn=Edwards)(sn=Morrell))' );

$f = Net::LDAP::FilterBuilder->new( sn => [ 'Gorwits', 'Edwards' ], givenName => 'Guy' );
is( "$f", '(&(|(sn=Gorwits)(sn=Edwards))(givenName=Guy))' );

$f = Net::LDAP::FilterBuilder->new( sn => [ 'Gorwits', 'Edwards' ] )->and( givenName => 'Oliver' );
is( "$f", '(&(|(sn=Gorwits)(sn=Edwards))(givenName=Oliver))' );

$f = Net::LDAP::FilterBuilder->new( sn => 'Gorwits' )->or( sn => 'Edwards' )->and( givenName => 'Oliver' );
is( "$f", '(&(|(sn=Gorwits)(sn=Edwards))(givenName=Oliver))' );

$f = Net::LDAP::FilterBuilder->new( sn => 'Gorwits' )->or( Net::LDAP::FilterBuilder->new( sn => 'Edwards' )->and( givenName => 'Oliver' ) );
is( "$f", '(|(sn=Gorwits)(&(sn=Edwards)(givenName=Oliver)))' );

$f = Net::LDAP::FilterBuilder->new( sn => 'Gorwits' )->or( sn => 'Edwards' )->and( givenName => 'Oliver' )->not;
is( "$f", '(!(&(|(sn=Gorwits)(sn=Edwards))(givenName=Oliver)))' );

$f = Net::LDAP::FilterBuilder->new( sn => ['Gorwits', 'Edwards'] )->and( Net::LDAP::FilterBuilder->new( givenName => 'Oliver' )->not );
is( "$f", '(&(|(sn=Gorwits)(sn=Edwards))(!(givenName=Oliver)))' );

$f = Net::LDAP::FilterBuilder->new( sn => 'foo*bar' );
is( "$f", '(sn=foo\*bar)' );

$f = Net::LDAP::FilterBuilder->new( sn => \'foo*bar' );
is( "$f", '(sn=foo*bar)' );

$f = Net::LDAP::FilterBuilder->new( sn => \'*' );
is( "$f", '(sn=*)' );

$f = Net::LDAP::FilterBuilder->new( '>=', dateOfBirth => '19700101000000Z' );
is( "$f", '(dateOfBirth>=19700101000000Z)' );
