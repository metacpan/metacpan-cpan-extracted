package Pandoc::Filter::HeaderIdentifiers;
use strict;
use warnings;
use 5.010;

our $VERSION = '0.34';

use parent 'Pandoc::Filter';
use Pandoc::Elements;

our @EXPORT = qw(header_identifier InPandocHeaderIdentifier);

## FUNCTIONS

sub header_identifier {
	my $id    = shift;
	my $ids   = shift;

	# stringify inline elements except footnotes
    $id = join '', @{
        pandoc_query( $id, sub {
            $_->is_inline and $_->name ne 'Note' ? $_->string : \undef
        })
    } if ref $id;

    # Convert all alphabetic characters to lowercase.
    $id = lc $id;

    # these steps not strictly documented but it is how Pandoc works
	$id =~ s/\p{^InPandocHeaderIdOrWs}+//g;
    $id =~ s/\p{WhiteSpace}+$//;

    # Replace all spaces and newlines with hyphens.
    $id =~ s/\p{WhiteSpace}+/-/g;

    # Remove all punctuation, except underscores, hyphens, periods, and whitespace.
	$id =~ s/\p{^InPandocHeaderIdentifier}//g;

    # remove everything up to the first letter
    $id =~ s/^[_.0-9-]+//;

    # if nothing is left, use the identifier 'section'
	$id ||= 'section';

	# add counter on repeated identifiers
	if ($ids and $ids->{$id}++) {
		$id .= '-' . ($ids->{$id}-1);
	}

	return $id;
}

## METHODS

sub new {
    bless { }, shift;
}

sub apply {
    my ($self, $doc) = @_;

    my $ids = @_ > 2 ? $_[2] : {};

    # collect existing identifiers
    $doc->walk( Header => sub {
        my $id = $_->id;
        return if $id !~ /^\p{InPandocHeaderIdentifier}+$/ or $id !~ /^\p{Letter}/;
        if ($id =~ /^(.+)-(\d+)$/) {
            $id = $1;
            $ids->{$id} = $2 unless defined $ids->{$id} and $ids->{$id} > $2;
        }
        $ids->{$id}++;
    } );

    # add missing identifiers
    $doc->walk( Header => sub {
        $_[0]->id( header_identifier( $_[0]->content, $ids ) ) if $_[0]->id eq '';
    });

    $doc;
}
	
## CHARACTER PROPERTIES

sub InPandocHeaderIdentifier {
	return "+utf8::Letter\n-utf8::Uppercase_Letter\n-utf8::Titlecase_Letter\n0030 0039\n005F\n002d 002e\n";
}

sub InPandocHeaderIdOrWs {
    return "+utf8::Whitespace\n+utf8::Letter\n-utf8::Uppercase_Letter\n-utf8::Titlecase_Letter\n0030 0039\n005F\n002d 002e\n";
}

__END__

=head1 NAME

Pandoc::Filter::HeaderIdentifiers - Add identifiers to headers

=head1 SYNOPSIS

  my $id = header_identifier( $header->content );       # calculate identifier

  Pandoc::Filter::HeaderIdentifiers->new->apply($doc);  # add all identifiers

=head1 DESCRIPTION

This L<Pandoc::Filter> adds identifier attributes (L<id|Pandoc::Elements/id>)
to all L<Headers|Pandoc::Elements/Header> elements. It uses the same algorithm
as internally used by pandoc.  The module also exports function
C<header_identifier> to calculate an identifier from a list of elements.

=head1 FUNCTIONS

=head2 header_identifier( $content [, $ids ] )

Returns an identifier for a given list of L<inlines|Pandoc::Elements/INLINE
ELEMENTS> or string (C<$content>). Optionally takes into account and updates
existing ids, given as hash reference mapping identifier to usage count
(C<$ids>).

=head1 METHODS

=head2 apply( $element [, $ids ] )

Add identifiers to all L<Header|Pandoc::Elements/Header> elements found at a
given element (typically a L<Document|Pandoc::Elements/Document>. A hash
reference of existing identifier counts (or an empty hash to get the new
counts) can be passed in addition.

=head1 CHARACTER PROPERTIES

=head2 InPandocHeaderIdentifier

Matches all Unicode lowercase letters, digits 0 to 9, underscore, hyphen, and
period. In the unlikely event that you want to check whether a given string
could have been generated as header identifier, use this:

  $id =~ /^\p{InPandocHeaderIdentifier}+$/ and $id =~ /^\p{Letter}/

=head1 SEE ALSO

L<http://pandoc.org/MANUAL.html#header-identifiers>

=cut
