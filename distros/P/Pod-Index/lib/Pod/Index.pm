package Pod::Index;

$VERSION = '0.14';

use strict;
use warnings;

1;

__END__


=head1 NAME

Pod::Index - Index and search PODs using XE<lt>> entries.

=head1 SYNOPSIS

    ### to create an index:
    use Pod::Index::Builder;

    my $p = Pod::Index::Builder->new;
    for my $file (@ARGV) {
        $p->parse_from_file($file);
    }

    $p->print_index("index.txt");


    ### to search for a keyword in the index:
    use Pod::Index::Search;

    my $q = Pod::Index::Search->new(
        filename => 'index.txt',
    );

    my @results = $q->search('getprotobyname');

    for my $r (@results) {
        printf "%s\t%s\n", $r->podname, $r->line;
        print $r->pod;
    }

=head1 DESCRIPTION

The Pod-Index distribution includes various modules for indexing and
searching POD that is appropriately marked with XE<lt>> POD codes.

C<Pod::Index>, as a module, does nothing. Everything is done by
L<Pod::Index::Builder>, L<Pod::Index::Search>, and other helper modules.

This document discusses some of the general issues with POD indexing;
specifically, the recommended conventions for the use of XE<lt>> codes.

=head1 BACKGROUND

The little-known (or at least little-used) XE<lt>> formatting code is 
described in L<perlpod>:

  "X<topic name>" -- an index entry
    This is ignored by most formatters, but some may use it for build-
    ing indexes.  It always renders as empty-string.  Example: "X<abso-
    lutizing relative URLs>"

=head1 CONVENTIONS FOR THE USE OF XE<lt>> CODES

=head2 Placement of the XE<lt>> entries

First, a definition. By "scope", I mean the part of the document that is 
deemed relevant to an index entry, and that may be extracted and shown 
in isolation by a processing or display tool. For example, perldoc -f 
considers the scope of a function to end at the beginning of the next =item, 
or at the end of the enclosing =over.

The XE<lt>> entries should be added at the end of a command or textblock 
paragraph (verbatim paragraphs are excluded). The scope of the index 
entry starts at the beginning of the paragraph to which it was attached; 
the end of the scope depends on the command type:

1) if the XE<lt>> is at the end of a textblock, the scope is that paragraph 
and zero or more verbatim paragraphs immediately following it.

2) if the XE<lt>> is at the end of a command paragraph, it depends on the 
type of command:

=over

=item =head1, head2, etc.

The scope ends right before the next heading with equal or higher level. That
is, a =head1 ends at the next =head1, and a =head2 ends at the 
next =head2 or =head1.

=item =item

The scope ends right before the next =item, or the =back
that terminates the containing list. Note: "empty" items are
not counted for terminating scopes, to allow for cases where
multiple =items head a block of text. For example,

    =item function
    X<function>
    X<otherfunction>

    =item otherfunction

    C<function> and C<otherfunction> do the same thing,
    even if they    have different names...

    =item lemonade

Here the scope of the XE<lt>function> and XE<lt>otherfunction> entries starts 
with "=item function", and ends right before "=item lemonade".

=back

3) other command paragraphs, such as =back, =over, =begin, =end, and =for 
should not be used for attaching XE<lt>> entries.


=head2 Content of the XE<lt>> entry.

=over

=item *

It should contain plain text without further formatting codes (with 
the possible exception of EE<lt>>).

=item * 

It should be in lowercase, unless caps are required due to case-sensitivity
or correctness.

=item * 

Non-word characters are allowed, so one can list things like operators 
and special variables.

=item * 

Use of synonyms is encouraged, to make things easier to find.

=item * 

To be consistent, words should be normalized to the singular whenever 
possible. For example, use XE<lt>operator> instead of XE<lt>operators>.

=item * 

The use of a comma in an index entry has a special meaning: it 
separates levels of hierarchy (or namespaces), as a way of classifying 
entries in more specific ways. For example, "XE<lt>operator, logical>", or 
"XE<lt>operator, logical, xor>". This information may be used by processing 
programs to arrange the entries, or for listing results when a user 
searches for a namespace that contains several entries.

=item * 

There's no limitation as to the number of times that a given entry can 
appear in a document or collection of documents. That is, it is not an 
error to have XE<lt>whatever> appear twice in the same file.

=back

=head1 VERSION

0.14

=head1 SEE ALSO

L<Pod::Index::Builder>,
L<Pod::Index::Search>,
L<Pod::Index::Entry>,
L<perlpod>

=head1 AUTHOR

Ivan Tubert-Brohman E<lt>itub@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2005 Ivan Tubert-Brohman. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same terms as
Perl itself.

=cut

