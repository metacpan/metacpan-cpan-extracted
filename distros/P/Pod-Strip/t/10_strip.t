use Test::More tests => 4;
use Pod::Strip;


{
    my $code=<<'EOCODE';

=pod

the great hello world script

=cut

# print it
print "Hello, world!\n";
EOCODE
    my $podless;
    my $p=Pod::Strip->new;
    $p->output_string(\$podless);
    $p->parse_string_document($code);
    is ($podless,'

# print it
print "Hello, world!\n";
','pod stripped');
}

{
    my $podless;
    my $p=Pod::Strip->new;
    $p->output_string(\$podless);
    $p->parse_file('lib/Pod/Strip.pm');

    unlike($podless,qr/Thomas Klausner/i);
    unlike($podless,qr/Synopsos/i);
    unlike($podless,qr/a new parser object/i);

 }
