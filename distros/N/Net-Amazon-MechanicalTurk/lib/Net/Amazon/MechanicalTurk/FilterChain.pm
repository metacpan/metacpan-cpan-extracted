package Net::Amazon::MechanicalTurk::FilterChain;
use strict;
use warnings;
use Net::Amazon::MechanicalTurk::BaseObject;

our $VERSION = '1.00';

our @ISA = qw{ Net::Amazon::MechanicalTurk::BaseObject };

#
# This module is used for managing "around style" interceptors for your code.
#

Net::Amazon::MechanicalTurk::FilterChain->attributes(qw{
    filters
});

sub init {
    my $self = shift;
    $self->setAttributes(@_);
    $self->filters([]) unless $self->filters;
}

sub execute {
    my ($self, $code, @params) = @_;
    my $filters = $self->filters;
    if ($#{$filters} < 0) {
        # bypass chain creation
        return $code->(@params);
    }
    else {
        return createChain($filters, 0, $code, \@params)->();
    }
}

sub filterCount {
    my $self = shift;
    return $#{$self->filters} + 1;
}

sub addFilter {
    my ($self, @params) = @_;
    if ($#params > 0) {
        unshift(@{$self->filters}, [@params]);
    }
    elsif ($#params == 0) {
        unshift(@{$self->filters}, $params[0]);
    }
}

sub hasFilter {
    my ($self, $code) = @_;
    my $filters = $self->filters;
    foreach my $filter (@$filters) {
        if (UNIVERSAL::isa($filter, "ARRAY")) {
            return 1 if ($filter->[0] == $code); 
        }
        else {
            return 1 if ($filter == $code);
        }
    }
}

sub removeAllFilters {
    my $self = shift;
    $self->filters([]);
}

sub removeFilter {
    my ($self, $code) = @_;
    my $filters = $self->filters;
    for (my $i=0; $i<=$#{$filters}; $i++) {
        if (UNIVERSAL::isa($filters->[$i], "ARRAY")) {
            next unless ($filters->[$i][0] == $code); 
        }
        else {
            next unless ($filters->[$i] == $code);
        }
        splice(@{$filters}, $i, 1);
        $i--;
    }
}

sub createChain {
    my ($filters, $pos, $target, $params) = @_;
    if (!defined($filters) or $pos > $#{$filters}) {
        return sub {
            return $target->(@$params);
        };
    }
    else {
        # A filter is either a CODE block
        # or an array where the 1st item is the CODE block
        # and the rest of the parameters are sent to the block.
        my $filter = $filters->[$pos];
        my @filterParams;
        if (UNIVERSAL::isa($filter, "ARRAY")) {
            @filterParams = @$filter;
            $filter = shift(@filterParams);
        }
        my $chain = createChain($filters, $pos+1, $target, $params);
        return sub {
            return $filter->($chain, $params, @filterParams);
        };
    }
}

return 1;
