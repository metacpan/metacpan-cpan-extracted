package SWISH::API::Remote::Results;
use SWISH::API::Remote::FunctionGenerator;
use strict;
use warnings;

############################################
use fields qw( results hits errors debugs iterator stopwords );


############################################
# results is a list of SWISH::API::Remote::Result objects,
# hits is an int of the number of hits found by swish-e
# errors is a list of lines
# debugs is a list of debug lines
# iterator is for NextResult() and SeekResult()
sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = {};
    bless( $self, $class );
    $self->{iterator} = 0;
    $self->{results}  = [];
    $self->{errors}   = [];
    $self->{hits}     = 0;
    $self->{stopwords} = '';
    #$self->{headers}   = undef;
    return $self;
}


############################################
sub Error {
    my $self = shift;
    return scalar( @{ $self->{errors} } );
}


############################################
sub ErrorString {
    my $self = shift;
    return join ( "\n", @{ $self->{errors} } ) . "\n";
}


############################################
sub SeekResult {
    my $self = shift;
    $self->{iterator} = shift || 0;
}


############################################
sub NextResult {
    my ($self) = @_;
    my $ret = undef;
    if ( $self->{iterator} < @{ $self->{results} } ) {
        $ret = $self->{results}[ $self->{iterator} ];
        $self->{iterator}++;
    }
    return $ret;
}


############################################
sub Hits {
    my $self = shift;
    if (@_) { $self->{hits} = $_[0] }
    else { return ( $self->{hits} || 0 ) }
}

############################################
sub Fetched {
    my $self = shift;
    exists( $self->{results} ) ? scalar( @{ $self->{results} } ) : 0;
}

############################################ 
sub AddResult {
    my ( $self, $result ) = @_;
    push ( @{ $self->{results} }, $result );
}

############################################ 
sub AddError {
    my ( $self, $error ) = @_;
    push ( @{ $self->{errors} }, $error );
}

############################################ 
sub AddDebug {
    my ( $self, $debug ) = @_;
    push ( @{ $self->{debugs} }, $debug );
}

############################################ 
# for conformance with SWISH::API
# TODO: Code this!!!
sub HeaderNames
{
    my $self = shift;
    my (%h);
    return sort keys %h;
}

############################################ 
# S::A vers 0.04 syntax , according to peknet
sub header_names { return HeaderNames(@_) }

############################################ 
SWISH::API::Remote::FunctionGenerator::makeaccessors(__PACKAGE__,
                                 qw ( results errors stopwords ));


1;
__END__

=head1 NAME

SWISH::API::Remote::Results - Represents the results of a search on a swished server

=head1 DESCRIPTION

Stores the results of a search from a swished server. Intended to be used with
SWISH::API::Remote.

=over 4

=item my $results = SWISH::API::Remote::Results->new()

returns a new SWISH::API::Remote::Results object. Normally 
called by SWISH::API::Remote for you.

=item my $error = $results->Error();

returns zero if there were no errors reported, non-zero otherwise.

=item my $error_string = $results->ErrorString();

returns the string representation of the error(s) returned
from the swished server.

=item my $result = $results->NextResult();

returns the next result fetched from the swished server. If there
are no more results for our query, returns undef

=item $results->SeekResults( $row_number );

Arranges for the next result retrieved by NextResult to be the
row with the passed number. Rows always start at 0, even when
using the BEGIN option to SWISH::API::Remote::Execute().

=item $results->Hits();

Returns the number of total hits found for the search.

=item $results->Fetched();

Returns the number of rows fetched for this search.

=item $results->HeaderNames();

Returns a sorted name keys of the header available for the swish-e results

=back

=head1 SEE ALSO

L<SWISH::API::Remote::Result>, L<SWISH::API::Remote>, L<swish-e>

=head1 AUTHOR

Josh Rabinowitz, E<lt>joshr@localdomainE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004-2006 by Josh Rabinowitz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.


=cut

1;
