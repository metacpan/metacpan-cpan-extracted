package Net::Amazon::MechanicalTurk::PagedResultsIterator;
use warnings;
use strict;
use Carp;
use Net::Amazon::MechanicalTurk::BaseObject;

our $VERSION = '1.00';

our @ISA = qw{ Net::Amazon::MechanicalTurk::BaseObject };
our %META_RESULT_FIELDS = (
    NumResults => 1,
    PageNumber => 1,
    TotalNumResults => 1,
    Request => 1
);

Net::Amazon::MechanicalTurk::PagedResultsIterator->attributes(qw{
    mturk
    operation
    params
    pageSize
    currentPage
    currentResults
    currentResultsPosition
});

sub init {
    my $self = shift;
    $self->setAttributes(@_);
    if (defined $self->params and $self->params->{PageSize}) {
        $self->pageSize($self->params->{PageSize});
    }
    $self->setAttributesIfNotDefined(
        params   => {},
        pageSize => 100
    );
    $self->assertRequiredAttributes(qw{
        mturk
        operation
    });
    $self->currentResults([]);
    $self->currentPage(0);
    $self->currentResultsPosition(0);
}

sub next {
    my ($self) = @_;
    
    my $array = $self->currentResults;
    return undef unless defined($array);

    # TODO: make sure this is right
    # perhaps the code should continue until it gets to a page with 0
    # results. The assumption here is that a page with less items
    # then the requested page size is the last page.    
    if ($self->currentResultsPosition > $#{$array}) {
        #if (($#{$array}+1) < $self->pageSize) {
        #    $self->currentResults(undef);
        #    return undef;
        #}
        #else {
            $self->currentPage($self->currentPage + 1);
            $self->loadPage;
        #}
    }
    
    $array = $self->currentResults;
    return undef unless defined($array);
    
    if ($self->currentResultsPosition > $#{$array}) {
        $self->currentResults(undef);
        return undef;
    }
    
    my $item = $array->[$self->currentResultsPosition];
    $self->currentResultsPosition($self->currentResultsPosition + 1);
    
    return $item;
}

sub loadPage {
    my ($self) = @_;
    my %params = %{$self->params};
    
    $params{PageNumber} = $self->currentPage;
    $params{PageSize} = $self->pageSize;
    
    my $result = $self->mturk->call($self->operation, \%params);
    
    if (!UNIVERSAL::isa($result, "HASH")) {
        Carp::croak("Unexpected result type for " . $self->operation . ".");
    }
    
    $self->currentResults(undef);
    $self->currentResultsPosition(0);
    
    while (my ($k,$v) = each %$result) {
        if (! exists $META_RESULT_FIELDS{$k}) {
            if (UNIVERSAL::isa($v, "ARRAY")) {
                $self->currentResults($v);
            }
            else {
                $self->currentResults([$v]);
            }
            last;
        }
    }
}

return 1;
