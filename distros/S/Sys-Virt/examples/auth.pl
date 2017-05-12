# -*- perl -*-
use strict;
use warnings;
use Sys::Virt;

my $addr = @ARGV ? shift @ARGV : "";
print "Addr $addr\n";
my $con = Sys::Virt->new(address => $addr, readonly => 0, auth => 1,
			 credlist => [
			   Sys::Virt::CRED_AUTHNAME,
			   Sys::Virt::CRED_PASSPHRASE,
			 ],
			 callback => sub {
			     my $creds = shift;


			     foreach my $cred (@{$creds}) {
				 if ($cred->{type} == Sys::Virt::CRED_AUTHNAME) {
				     $cred->{result} = "test";
				 }
				 if ($cred->{type} == Sys::Virt::CRED_PASSPHRASE) {
				     $cred->{result} = "123456";
				 }

			     }
			     return 0;
			 });

print "VMM type: ", $con->get_type(), "\n";

