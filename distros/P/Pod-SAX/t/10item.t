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

# TODO : add some real tests here (manually checked at the moment)

__DATA__

=head1 Item test

Some =item things to test

=head2 Bulleted Lists

=over 4

=item * bulleted list

=item * second bullet

=item *

Bullet on its own

=item *

And one more

=back

=head2 Numbered Lists

=over 4

=item 1. numbered list

=item 2. second number

=item 

=back

=head2 Ordinary lists

=over 4

=item No prefix list

=item More

=back

=head2 Nested Lists

=over 4

=item Here's a nested list. Top level

=over 4

=item Level 1

=over 4

=item Level 2

=back

=back

=item Back at the top level

=back

=head2 No list - just =over =back (indent)

=over 2

Something indented

=back

=head2 List without ending

=over 4

=item Foo

Blah Blah

=cut
