package RTF::Encode;
# vim:ts=4:shiftwidth=4:expandtab

# ABSTRACT: Escapes strings into RTF

use strict;
use warnings;

our $VERSION = '1.01';

=head1 NAME

RTF::Encode - Escapes strings into RTF

=head1 SYNOPSIS

    use RTF::Encode qw/ encode_rtf /;
    print encode_rtf("Smiling cat with heart shaped eyes, ".chr(0x1f63b);

=cut

use Encode qw/ encode /;
use parent qw/ Exporter /;

our (@EXPORT_OK);

BEGIN {
   @EXPORT_OK = qw(encode_rtf);
}

=head2 encode_rtf

    my $rtf = encode_rtf($unicode);

This function takes a string, which may contain Unicode characters, and
returns a string escaped to be used in an RTF file. It can be used to safely
insert arbitrary text into a template RTF file, perhaps via L<Template>.

C<\uN> escaping is always used, even for characters less than 255, because
the alternative, C<\'hh> needs to know the current code page.

Line breaks are encoded as line breaks, C<\line>, not as paragraphs.

C<\ucN> is not generated, it does not appear to be necessary.

=cut

sub encode_rtf {
    my ($string) = @_;

    my $output = "";

    while ($string ne "") {
        $string =~ /^([A-Za-z0-9_\.\, ]*)(.?)(.*)$/s or die "regexp unexpectedly failed for '$string'";

        $output .= $1;
        $string = $3;

        if (!defined $2) {
        }
        elsif ($2 eq "\n") {
            $output .= "\\line\n";
        }
        elsif ($2 eq "\t") {
            $output .= "\\tab ";
        }
        else {
            my $char = $2;
            my $utf16 = encode('UTF16-LE', $char, Encode::FB_CROAK);
            my @shorts = unpack("s<*", $utf16);
            foreach my $s (@shorts) {
                $output .= "\\u$s\\'3f";
            }
        }
    }
    return $output;
}

=head1 SPECIFICATION

L<http://www.biblioscape.com/rtf15_spec.htm>

=head1 SEE ALSO

=over

=item L<RTF::Writer>

=back

=head1 AUTHOR

Dave Lambley <dlambley@cpan.org>

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

1;
