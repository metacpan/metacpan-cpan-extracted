package Serengeti::Backend::Native::DocumentElement;

use strict;
use warnings;

use Scalar::Util qw(refaddr weaken);
use base qw(HTML::TreeBuilder::XPath);

{
    my %owner_document;

    sub set_owner_document {
        my ($self, $document) = @_;
        $owner_document{refaddr $self} = $document;
        weaken $owner_document{refaddr $self};
    }

    sub owner_document {
        my $self = shift;
        return $owner_document{refaddr $self};
    }
}

sub DESTROY {
    my $self = shift;
    $self->delete;
}
1;