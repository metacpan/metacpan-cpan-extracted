package Pod::Knit::Plugin::Authors;
our $AUTHORITY = 'cpan:YANICK';
$Pod::Knit::Plugin::Authors::VERSION = '0.0.1';
use strict;
use warnings;

use Web::Query;
use Moose;

extends 'Pod::Knit::Plugin';
with 'Pod::Knit::DOM::WebQuery';

use experimental 'signatures';

has "authors" => (
    traits => [ 'Array' ],
    isa => 'ArrayRef',
    is => 'ro',
    lazy => 1,
    handles => {
        all_authors => 'elements',
    },
    default => sub {
        my $self = shift;
        $self->stash->{authors} || [];
    },
);

sub munge($self, $doc) {

    my @authors = $self->all_authors
        or return;

    my $title = 'AUTHORS';

    if ( @authors == 1 ) {
        chop $title;
        $doc->find_or_create_section(
            $title,
            1,
            $title,
            para => @authors
        );
    }
    else {
        $doc->dom->append(
            $self->xml_write( section => [
                head1 => $title,
                'over-text' => [
                    map { ('item-text' => $_) } @authors
                ]
            ])
        )
    }
} 

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Knit::Plugin::Authors

=head1 VERSION

version 0.0.1

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full text of the license can be found in the F<LICENSE> file included in
this distribution.

=cut

