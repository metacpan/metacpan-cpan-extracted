package PYX::Utils;

use base qw(Exporter);
use strict;
use warnings;

use HTML::Entities qw(decode_entities);
use Readonly;

# Constants.
Readonly::Array our @EXPORT_OK => qw(decode encode entity_decode entity_encode);
Readonly::Hash our %ENTITIES => (
        '<' => '&lt;',
        q{&} => '&amp;',
        q{"} => '&quot;',
);
Readonly::Scalar our $ENTITIES => join q{}, keys %ENTITIES;

our $VERSION = 0.06;

# Decode chars.
sub decode {
	my $text = shift;
	$text =~ s/\n/\\n/gms;
	return $text;
}

# Encode chars.
sub encode {
	my $text = shift;
	$text =~ s/\\n/\n/gms;
	return $text;
}

# Decode entities.
sub entity_decode {
	my $text = shift;
	return decode_entities($text);
}

# Encode some chars for HTML/XML/SGML.
sub entity_encode {
	my $text = shift;
	$text =~ s/([$ENTITIES])/$ENTITIES{$1}/gms;
	return $text;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

PYX::Utils - A perl module for PYX common utilities.

=head1 SYNOPSIS

 use PYX::Utils;

 my $decoded_text = decode($text);
 my $encoded_text = encode($text);
 my $decoded_text = entity_decode($text);
 my $encoded_text = entity_encode($text);

=head1 SUBROUTINES

=over 8

=item C<decode($text)>

 Decode characters.
 Currently decode newline to '\n'.
 Returns decoded text.

=item C<encode($text)>

 Encode characters.
 Currently encode '\n' to newline.
 Returns encoded text.

=item C<entity_decode($text)>

 Decode entities.
 - '&lt;' => '<'
 - '&amp;' => '&'
 - '&quot;' => '"'
 Returns decoded text.

=item C<entity_encode($text)>

 Encode some chars for HTML/XML/SGML.
 Currenctly encode these characters:
 - '<' => '&lt;'
 - '&' => '&amp;'
 - '"' => '&quot;'
 Returns encoded text.

=back

=head1 EXAMPLE1

 use strict;
 use warnings;

 use PYX::Utils qw(decode);

 # Text.
 my $text = "foo\nbar";

 # Decode.
 my $decoded_text = decode($text);

 # Print to output.
 print "Text: $text\n";
 print "Decoded text: $decoded_text\n";

 # Output:
 # Text: foo
 # bar
 # Decoded text: foo\nbar

=head1 EXAMPLE2

 use strict;
 use warnings;

 use PYX::Utils qw(encode);

 # Text.
 my $text = 'foo\nbar';

 # Encode text.
 my $encoded_text = encode($text);

 # Print to output.
 print "Text: $text\n";
 print "Encoded text: $encoded_text\n";

 # Output:
 # Text: foo\nbar
 # Encoded text: foo
 # bar

=head1 EXAMPLE3

 use strict;
 use warnings;

 use PYX::Utils qw(entity_decode);

 # Text.
 my $text = 'foo&lt;&amp;&quot;bar';

 # Decode entities.
 my $decoded_text = entity_decode($text);

 # Print to output.
 print "Text: $text\n";
 print "Decoded entities: $decoded_text\n";

 # Output:
 # Text: foo&lt;&amp;&quot;bar
 # Decoded entities: foo<&"bar

=head1 EXAMPLE4

 use strict;
 use warnings;

 use PYX::Utils qw(entity_encode);

 # Text.
 my $text = 'foo<&"bar';

 # Encode entities.
 my $encoded_text = entity_encode($text);

 # Print to output.
 print "Text: $text\n";
 print "Encoded text: $encoded_text\n";

 # Output:
 # Text: foo<&"bar
 # Encoded text: foo&lt;&amp;&quot;bar

=head1 DEPENDENCIES

L<Exporter>,
L<HTML::Entities>,
L<Readonly>.

=head1 SEE ALSO

=over

=item L<Task::PYX>

Install the PYX modules.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/PYX-Utils>

=head1 AUTHOR

Michal Josef Špaček L<skim@cpan.org>

=head1 LICENSE AND COPYRIGHT

© 2005-2020 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.06

=cut
