package Perl6::Pod::FormattingCode::X;

=pod

=head1 NAME

Perl6::Pod::FormattingCode::X - index entry

=head1 SYNOPSIS


  An X<array|arrays> is an ordered list of scalars indexed by number,
  starting with 0. A X<hash|hashes> is an unordered collection of
  scalar values indexed by their associated string key.
  
  A X<hash|hashes, definition of; associative arrays>
  is an unordered collection of scalar values indexed by their
  associated string key.


=head1 DESCRIPTION

Anything enclosed in an C<< XE<lt>E<gt> >> code is an B<index entry>. The contents of the code are both formatted into the document and used as the (case-insensitive) index entry:

    An X<array> is an ordered list of scalars indexed by number,
    starting with 0. A X<hash> is an unordered collection of scalar
    values indexed by their associated string key.

You can specify an index entry in which the indexed text and the index entry are different, by separating the two with a vertical bar:

    An X<array|arrays> is an ordered list of scalars indexed by number,
    starting with 0. A X<hash|hashes> is an unordered collection of
    scalar values indexed by their associated string key.

In the two-part form, the index entry comes after the bar and is case-sensitive.

You can specify hierarchical index entries by separating indexing levels with commas:

    An X<array|arrays, definition of> is an ordered list of scalars
    indexed by number, starting with 0. A X<hash|hashes, definition of>
    is an unordered collection of scalar values indexed by their
    associated string key.

You can specify two or more entries for a single indexed text, by separating the entries with semicolons:

    A X<hash|hashes, definition of; associative arrays>
    is an unordered collection of scalar values indexed by their
    associated string key.

The indexed text can be empty, creating a "zero-width" index entry:

    X<|puns, deliberate>This is called the "Orcish Manoeuvre"
    because you "OR" the "cache".


Exported :

=over 

=item *  docbook 

     <indexterm>
        <primary>information</primary>
        <secondary>dissemination</secondary>
     </indexterm>

L<http://www.docbook.org/tdg/en/html/index.html>
L<http://www.docbook.org/tdg/en/html/indexterm.html>

=cut

use warnings;
use strict;
use Data::Dumper;
use Perl6::Pod::FormattingCode;
use base 'Perl6::Pod::FormattingCode';
our $VERSION = '0.01';

=head2 process_index $text


=cut

sub process_index {
    my ( $self, $src_string ) = @_;
    my ( $text, $index ) = split( /\s*\|\s*/, $src_string );
    unless ( defined $index ) {
        $index = $text;
    }
    $index = [ split( /\s*;\s*/, $index ) ];
    wantarray() ? ( $text, $index ) : $text;
}

sub split_text_entry {
    my ( $self, $str ) = @_;
    my ( $text, $index ) = split( /\s*\|\s*/, $str );
    unless ( defined $index ) {
        $index = $text;
    }
    for ( $text, $index ) {
        s/^\s+//;
        s/\s+$//;
    }
    wantarray() ? ( $text, $index ) : $text;
}

sub on_para {
    my ( $self, $parser, $txt ) = @_;
    my $attr = $self->attrs_by_name;
    ( $attr->{index_text}, $attr->{index_entry} ) =
      $self->split_text_entry($txt);
    $attr->{index_text};
}

sub to_xhtml {
    my $self   = shift;
    my $parser = shift;
    return $self->attrs_by_name->{index_text};
}

sub to_docbook {
    my ($self, $to )= @_;
    $to->write($self->{text});
}
sub to_docbook_ {
    my $self   = shift;
    my $parser = shift;
    my $attr   = $self->attrs_by_name;
    my ( $itext, $ientry ) = ( $attr->{index_text}, $attr->{index_entry} );
    my @elements;

    #determine terms and levels
    foreach my $term_line ( split( /\s*;\s*/, $ientry ) ) {
        my $el_indexterm = $parser->mk_element('indexterm');

        #get levels (only two )
        my ( $l1, $l2 ) = split( /\s*,\s*/, $term_line );
        $el_indexterm->add_content( $parser->mk_element('primary')
              ->add_content( $parser->mk_characters($l1) ) )
          if $l1;
        $el_indexterm->add_content( $parser->mk_element('secondary')
              ->add_content( $parser->mk_characters($l2) ) )
          if defined $l2;
        push @elements, $el_indexterm;
    }
    return [ $self->attrs_by_name->{index_text}, @elements ];
}

1;

__END__

=head1 SEE ALSO

L<http://zag.ru/perl6-pod/S26.html>,
Perldoc Pod to HTML converter: L<http://zag.ru/perl6-pod/>,
Perl6::Pod::Lib

=head1 AUTHOR

Zahatski Aliaksandr, <zag@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2015 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

