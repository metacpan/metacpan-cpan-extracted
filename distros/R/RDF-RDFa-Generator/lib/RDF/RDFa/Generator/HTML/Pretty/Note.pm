=head1 NAME

RDF::RDFa::Generator::HTML::Pretty::Note - a note about something

=cut

package RDF::RDFa::Generator::HTML::Pretty::Note;

use 5.008;
use strict;
use constant XHTML_NS => 'http://www.w3.org/1999/xhtml';
use XML::LibXML qw':all';

our $VERSION = '0.103';

=head1 DESCRIPTION

Often you'll want to create your own subclass of this as the basic notes are pretty
limited (plain text only).

=head2 Constructor

=over 4

=item C<< $note = RDF::RDFa::Generator::HTML::Pretty::Note->new($subject, $text) >>

$subject is an RDF::Trine::Node (though probably not a Literal!) indicating the
subject of the note. $text is the plain text content of the note.

=back

=cut

sub new
{
	my ($class, $subject, $text) = @_;
	
	return bless {
		'subject' => $subject,
		'text'    => $text,
		}, $class;
}

=head2 Public Methods

=over 4

=item C<< $note->is_relevent_to($node) >>

$node is an RDF::Trine::Node. Checks if the subject of $note is $node.

Alias: is_relelvant_to.

=cut

sub is_relevant_to
{
	my ($self, $something) = @_;
	return $self->{'subject'}->equal($something);
}

*is_relevent_to = \&is_relevant_to;

=item C<< $note->node($namespace, $tagname) >>

Gets an XML::LibXML::Element representing the note. $namespace and $tagname
are used to create the new element. If an unexpected namespace or tagname is
supplied, may die.

Expected namespace is 'http://www.w3.org/1999/xhtml'. Expected tagname is any XHTML
tag that can contain text nodes.

=back

=cut

sub node
{
	my ($self, $namespace, $element) = @_;
	die "unknown namespace" unless $namespace eq XHTML_NS;
	
	my $node = XML::LibXML::Element->new($element);
	$node->setNamespace($namespace, undef, 1);
	
	$node->appendTextNode($self->{'text'});
	
	return $node;
}

1;

__END__

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/>.

=head1 SEE ALSO

L<RDF::RDFa::Generator>,
L<RDF::RDFa::Linter>.

L<http://www.perlrdf.org/>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2010 by Toby Inkster

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

