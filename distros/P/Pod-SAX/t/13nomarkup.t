use Test;
BEGIN { plan tests => 4 }
use Pod::SAX;
use XML::SAX::Writer;

my $output = '';
my $p = Pod::SAX->new(
            Handler => XML::SAX::Writer->new(
                Output => \$output
                )
            );

ok($p);
my $str = join('', <DATA>);
ok($str, qr/=pod/s, "Read DATA ok");
$p->parse_string($str);
ok($output);
print "$output\n";
ok($output, qr/<pod>.*<\/pod>/s, "Matches basic pod outline");

__DATA__

=pod

SomePod - Some Pod to parse
