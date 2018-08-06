package Pod::Knit::Plugin::Sort;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: Reorder sections
$Pod::Knit::Plugin::Sort::VERSION = '0.0.1';
use 5.10.0;
use strict;
use warnings;

use List::AllUtils qw/ part /;

use Moose;

extends 'Pod::Knit::Plugin';
with 'Pod::Knit::DOM::WebQuery';

use experimental 'signatures', 'postderef';

has "order" => (
    isa => 'ArrayRef',
    is => 'ro',
    lazy => 1,
    default => sub {
        []
    },
);

sub munge( $self, $doc ) {

    my $sections = $doc->dom->find( 'head1' )->map(sub{ $_->parent });

    my $i = 0;
    my %index = map { $_ => $i++ } $self->order->@*;
    my $rest = $index{'*'} || $i;

    my @order = 
        map { $_ ? @$_ : () } 
        part { $index{ $_->find('head1')->text } // $rest } @$sections;

    for( @order ) {
        $_->detach;
        $doc->dom->append($_);
    }
}




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Knit::Plugin::Sort - Reorder sections

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

