
package TestCerts;

# Copyright (C) 2009  NZ Registry Services
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the Artistic License 2.0 or later.  You should
# have received a copy of the Artistic License the file COPYING.txt.
# If not, see <http://www.perlfoundation.org/artistic_license_2_0>

my $cert_dir = "t/certs";

print STDERR "*** making test certificates\n";
my $output = `$cert_dir/make-test-certs.sh 0</dev/null 2>&1`;
if ( $? != 0 ) {
	print STDERR "*** error making test certificates:\n";
	print $output;
}
else {
	print STDERR "*** done making test certificates\n";
}

1;

