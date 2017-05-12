package SRU::Response::Term;
{
  $SRU::Response::Term::VERSION = '1.01';
}
#ABSTRACT: A class for representing terms in a Scan response

use strict;
use warnings;
use SRU::Utils qw( error );
use SRU::Utils::XML qw( element elementNoEscape );
use base qw( Class::Accessor );


sub new {
    my ($class, %args) = @_;
    return error( "must supply value parameter in call to new()" )
        if ! exists $args{value};
    return $class->SUPER::new( \%args );
}


SRU::Response::Term->mk_accessors( qw(
    value
    numberOfRecords
    displayTerm
    whereInList
    extraTermData
) );


sub asXML {
    my $self = shift;
    return 
        elementNoEscape( 'term', 
            element( 'value', $self->value() ) . 
            element( 'numberOfRecords', $self->numberOfRecords() ) . 
            element( 'displayTerm', $self->displayTerm() ) . 
            element( 'whereInList', $self->whereInList() ) . 
            elementNoEscape( 'extraTermData', $self->extraTermData() )
        );
}

1;

__END__

=pod

=head1 NAME

SRU::Response::Term - A class for representing terms in a Scan response

=head1 SYNOPSIS

=head1 DESCRIPTION

A SRU::Response::Term object bundles up information about a single
term contained in a SRU::Response::Scan object. A scan object can
contain multiple term objects.

=head1 METHODS

=head2 new()

THe constructor which you must at least pass the value parameter:

    my $term = SRU::Response::Term->new( term => "Foo Fighter" );

In addition you can pass the numberOfRecords, displayTerm, whereInList,
and extraTermData parameters, or set them separately with their
accessors.

=cut

=head2 value()

The term exactly as it appears in the index. This term should be able to be
sent in a query as is to retrieve the records it derives from. 

=head2 numberOfRecords()

The number of records which would be matched if the index in the request's
scanClause was searched with the term in the 'value' field. 

=head2 displayTerm()

A string to display to the end user in place of the term itself. For example
this might add back in stopwords which do not appear in the index, or diacritics
which have been normalised. 

=head2 whereInList()

A flag to indicate the position of the term within the complete term list. It
must be one of the following values: 'first' (the first term), 'last' (the last
term), 'only' (the only term) or 'inner' (any other term). 

=head2 extraTermData()

Additional profile specific information. More details are available in the
extensions section.

=cut

=head2 asXML()

=cut
=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ed Summers.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
