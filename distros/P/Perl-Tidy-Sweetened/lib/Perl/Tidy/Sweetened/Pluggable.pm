package Perl::Tidy::Sweetened::Pluggable;

# ABSTRACT: Simple object to facilitate a pluggable filter architecture

use strict;
use warnings;

our $VERSION = '1.16';

sub new {
    my ( $class, %args ) = @_;
    return bless {%args}, $class;
}

sub filters { return ( $_[0]->{filters} ||= [] ) }

sub add_filter {
    my $self = shift;
    push @{ $self->filters }, @_;
}

sub prefilter {
    my ( $self, $code ) = @_;
    for my $filter ( @{ $self->filters } ) {
        $code = $filter->prefilter($code);
    }

    # warn "After prefilter, before tidy\n";
    # warn $code;

    return $code;
}

sub postfilter {
    my ( $self, $code ) = @_;

    # warn "After tidy, before postfilter\n";
    # warn $code;

    for my $filter ( @{ $self->filters } ) {
        $code = $filter->postfilter($code);
    }
    return $code;
}

1;

__END__

=pod

=head1 NAME

Perl::Tidy::Sweetened::Pluggable - Simple object to facilitate a pluggable filter architecture

=head1 VERSION

version 1.16

=head1 SYNOPSIS

    our $plugins = Perl::Tidy::Sweetened::Pluggable->new();

    $plugins->add_filter(
        Perl::Tidy::Sweetened::Keyword::SubSignature->new(
            keyword => 'method',
            marker  => 'METHOD',
        ) );

    $plugins->prefilter( $code );
    $plugins->postfilter( $code );

=head1 DESCRIPTION

Builds a pluggable, chainable list of filters.

=head1 AUTHOR

Mark Grimes E<lt>mgrimes@cpan.orgE<gt>

=head1 SOURCE

Source repository is at L<https://github.com/mvgrimes/Perl-Tidy-Sweetened>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<http://github.com/mvgrimes/Perl-Tidy-Sweetened/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Mark Grimes E<lt>mgrimes@cpan.orgE<gt>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
