#!/usr/bin/env perl

use Net::OneTimeSecret;

# Note: replace these with yours in order for this to work!
my $customerId  = 'chris@onetimesecret.com';
my $testApiKey  = '4dc74a03fwr9aya5qur5wa8vavo4gih1hasj6181';

my $api = Net::OneTimeSecret->new( $customerId, $testApiKey );
my $result = $api->shareSecret( 'Jazz, jazz and more jazz.',
                   passphrase => 'thepassword',
                   recipient => 'kyle@shoffle.com',
                   ttl => 7200,
                 );
printf( "%s\n", $result->{secret_key} );

my $secret = $api->retrieveSecret( $result->{secret_key}, passphrase => "thepassword" );
printf( "%s\n", $secret->{value} );
