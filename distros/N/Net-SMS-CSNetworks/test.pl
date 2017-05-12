#!/usr/bin/perl

use Net::SMS::CSNetworks;

  my $sms = Net::SMS::CSNetworks->new(
        username => 'korisnik', password => 'lozinka'
  );

  my ($id, $status, $response) = $sms->send_sms(
        MESSAGE => "All your base are belong to us",
        DESTADDR  => '1234567890',
  );


print "$id   $status    $response\n";