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

Sequences

=head1 DESCRIPTION

A sequence looks like EE<lt>thisE<gt>, or a IE<lt>I<this>E<gt>...

Alternately, we can use multiple delimeters:

Such as C<<< some code using >> arrows >>>.

Or I<<<< Some italics with space >>>>.

Testing L<?|WikiWordLink>

=cut
