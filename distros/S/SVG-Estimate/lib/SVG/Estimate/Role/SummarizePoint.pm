package SVG::Estimate::Role::SummarizePoint;
$SVG::Estimate::Role::SummarizePoint::VERSION = '1.0115';
use strict;
use Moo::Role;

=head1 NAME

SVG::Estimate::Role::SummarizePoint - Output information about $self->point when summarizing an element

=head1 VERSION

version 1.0115

=cut

after summarize_myself => sub {
    my $self = shift;
    printf "\n\tPoint: [%s, %s]", @{ $self->point };
};

1;
