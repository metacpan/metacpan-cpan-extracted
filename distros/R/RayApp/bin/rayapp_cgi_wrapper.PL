#!perl -w

use Config;

my $filename = shift;
if (not defined $filename) {
	$filename = $0;
	$filename =~ s/\.PL$//;
}
open OUT, ">$filename" or die "Can't create $filename: $!";
chmod(0755, $filename);

print OUT "$Config{'startperl'} -w\n";

print OUT <<'EOF'

use RayApp::CGI ();
use strict;

RayApp::CGI::handler();

EOF
