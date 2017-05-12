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
ok($str, qr/=head1.*=cut/s, "Read DATA ok");
$p->parse_string($str);
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

=head1 Another top title

=head2 With a subtitle

=head3 and a head3 (do we support head3?)

=head4 what about head4?

=cut
