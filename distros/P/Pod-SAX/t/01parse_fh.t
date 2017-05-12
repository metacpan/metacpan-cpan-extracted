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
$_ = <DATA>;
$p->parse_file(\*DATA);
ok($output);
print "$output\n";
ok($output, qr/<pod>.*<\/pod>/s, "Matches basic pod outline");

__DATA__

=head1 NAME

SomePod - Some Pod to parse

=head1 DESCRIPTION

Foo

=head2 Sub Title

More

=cut
