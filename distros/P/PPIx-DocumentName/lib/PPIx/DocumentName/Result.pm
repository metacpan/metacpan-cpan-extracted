package PPIx::DocumentName::Result;

use strict;
use warnings;
use 5.006;
use overload
  '""'     => sub { shift->to_string },
  bool     => sub { 1 },
  fallback => 1;

# ABSTRACT: Full result set for PPIx::DocumentName
our $VERSION = '1.01'; # VERSION


sub _new
{
  my($class, $name, $document, $node) = @_;
  bless {
    name     => $name,
    document => $document,
    node     => $node,
  }, $class;
}

sub name      { shift->{name}     }
sub document  { shift->{document} }
sub node      { shift->{node}     }
sub to_string { shift->{name}     }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PPIx::DocumentName::Result - Full result set for PPIx::DocumentName

=head1 VERSION

version 1.01

=head1 SYNOPSIS

 use PPIx::DocumentName 1.00 -api => 1;
 my $result = PPIx::DocumentName->extract( $ppi_document );
 
 # say the "name" of the document
 say $result->name;
 
 # the result object can also be stringified into the name found:
 say "$result";
 
 # get the full PPI::Document object for the entire document
 my $ppi = $result->document;
 
 # get the node where we found the name
 # (usually a PPI::Statement::Package or PPI::Token::Comment)
 my $node = $result->node;
 
 # get the location where we found the name
 my $location = $result->node->location;

=head1 DESCRIPTION

This class represents the results from L<PPIx::DocumentName> when running under
its new C<< -api => 1 >> API.

=head1 METHODS

=head2 name

 my $name = $result->name;

Returns the name that was found in the document.

=head2 to_string

 my $str = $result->to_string;
 my $str = "$result";

Convert this object to a string.  This is the same as the C<name> method.  This
method will also be invoked if stringified inside a double quoted string.

=head2 document

 my $ppi = $result->document;

Returns the L<PPI::Document> of the document.

=head2 node

 my $node = $result->node;

Returns the L<PPI::Node> where the name was found.  This will usually be either
L<PPI::Statement::Package> or L<PPI::Token::Comment>, although other types could
be used in the future.

=head1 SEE ALSO

=over 4

=item L<PPIx::DocumentName>

Main module that generates objects of this class.

=back

=head1 CAVEATS

For C<node> to be useful, the C<document> object needs to remain in scope, this is the
main reason the result object keeps it around, so if you want to use the C<node>
to get the location information, make sure that you do not throw away the result object.

Bad:

 my $node = PPIx::DocumentName->extract( $ppi_document )->node;
 my $location = $node->location;  # undef

Fine:

 my $result = PPIx::DocumentName->extract( $ppi_document );
 my $node = $result->node;
 my $location = $node->location;  # ok

=head1 AUTHORS

=over 4

=item *

Kent Fredric <kentnl@cpan.org>

=item *

Graham Ollis <plicease@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015-2021 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
