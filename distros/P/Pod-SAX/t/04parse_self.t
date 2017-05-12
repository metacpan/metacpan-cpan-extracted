use strict;
use Test;
BEGIN { plan tests => 3 }
use Pod::SAX;
use XML::SAX::Writer;

my $output = '';
my $p = Pod::SAX->new(
               Handler => XML::SAX::Writer->new(
                   Output => \$output
               )
        );

ok($p);

$p->parse_uri("lib/Pod/SAX.pm");
ok($output);
print "$output\n";
ok($output, qr/<pod>.*<\/pod>/s, "Matches basic pod outline");
