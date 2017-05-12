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

=head1 Verbatim tests

  Some verbatim code to test
  to see if we end up with a split
  
  here despite not having a completely
  blank line there.
  
  Also what happens with E<lchevron> sequences
  in verbatim sections?

=cut
