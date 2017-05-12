package Perlipse::SourceParser::Visitors::Visitor;

use strict;

use Perlipse::SourceParser::Utils;

=head1 NAME

Perlipse::SourceParser::Visitors::Visitor -- visitor base class

=cut

sub accepts
{
    my $class = shift;
    my ($element) = @_;
    
    return (grep {$element->class eq $_} $class->_supported_elements());
}

sub endVisit
{
    my $class = shift;

}

sub utils
{
    return 'Perlipse::SourceParser::Utils';
}

# subclass

=item B<_supported_elements>

returns a list of L<PPI::Element> types supported by the visitor implementation

=cut

sub _supported_elements
{
    die 'bad monkey! implement me!';
}

1;