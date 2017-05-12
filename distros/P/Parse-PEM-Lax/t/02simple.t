
use Test::More tests => 4;

use Parse::PEM::Lax;

my $pem = Parse::PEM::Lax->from_string(q{
  
 Here are the certs!
 
 -----BEGIN BAR-----
 data1
 -----END BAR-----
 
 -----BEGIN FOO-----
 data2
 -----END FOO-----
 
 Indently yours.
 
});

my @sections = $pem->extract_sections;

like $sections[0], qr/data1/, 'found cert 1';
like $sections[1], qr/data2/, 'found cert 2';

for (@sections) {
  my ($reparsed) = Parse::PEM::Lax->from_string($_)->extract_sections;
  is $reparsed, $_, 'idempotence ok';
}
