use strict;
use warnings;

use Test::Most;

use Pod::Knit::Document;

my $doc = Pod::Knit::Document->new(
    content => <<'END',

some code at the top

=head1 Stuff

Yadah  B<bold> I<italic> L<linkie> C<code> B<bold> C<code2>


    Verbatim

=over

=item title

Content

=back

=head1 SYNOPSIS

    verbatim stuff

=head1 Foo

This is something that should be on several lines because 
it's long, you see, in fact
beyond the recommended 78 characters


END
);

like $doc->xml_pod => qr/<document/i, "->xml_pod";

subtest as_pod => sub {
    $_ = $doc->as_pod;

    like $_ => qr/=head1 Stuff/, "->as_pod";

    like $_ => qr/
        ^=over 
        .*? 
        ^=back
    /xms, 'over / back';

    like $_ => qr/L<linkie>/, 'L<>';

    like $_ => qr/L<linkie> C<code>/, "should be a space there";

    like $_ => qr/^=head1 SYNOPSIS\n\n\s+verbatim stuff/m;

    like $_ => qr/This is something.*?\n.*?78 characters/, "wrapping paragraphs";
};

like $doc->as_code => qr/some code at the top/, '->as_code';

done_testing;
