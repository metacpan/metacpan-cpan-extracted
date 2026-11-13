package Praxo::Adapters::Retriever;

use strict;
use warnings;
use Praxo::Errors qw(praxo_error);

sub document {
    my (%args) = @_;
    return {
        id => $args{id} // '',
        content => $args{content} // '',
        metadata => $args{metadata},
        score => $args{score},
    };
}

sub func_retriever {
    my ($code) = @_;
    return $code;
}

sub retrieve_documents {
    my ($retriever, $query, $limit) = @_;
    praxo_error('RETRIEVER_INVALID', 'retriever: invalid limit')
        if $limit < 0;
    my $documents = $retriever->($query, $limit);
    return ref($documents) eq 'ARRAY' ? $documents : [];
}

1;
