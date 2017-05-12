package RDF::SKOS::Scheme;

use strict;
use warnings;

=head1 NAME

RDF::SKOS::Scheme - SKOS - Concept Scheme Class

=head1 SYNOPSIS

    use RDF::SKOS;
    my $skos = new RDF::SKOS;
    # ...
    my @ss = $skos->schemes;
    #
    my $scheme = $skos->scheme ('some_scheme');
    my @tops   = $scheme->topConcepts;

=head1 DESCRIPTION

This class simply captures a SKOS I<scheme>. Nothing exciting.

=head1 INTERFACE

=head2 Constructor

The constructor expects as first parameter the SKOS object itself, then the ID of the scheme.

=cut

sub new {
    my $class = shift;
    my $skos  = shift;
    my $cid   = shift;
    return bless { @_, skos => $skos, id => $cid }, $class;
}

=pod

=head2 Methods

=over

=item B<topConcepts>

I<@cs> = I<$scheme>->topConcepts

This returns a list of L<RDF::SKOS::Concept> objects.

=cut

sub topConcepts {
    my $self = shift;
    return $self->{skos}->topConcepts ($self->{id});
}

=pod

=back

=head1 AUTHOR

Robert Barta, C<< <drrho at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-rdf-skos at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=RDF-SKOS>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2009 Robert Barta, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl
itself.

=cut

our $VERSION = '0.01';

"against all odds";

__END__
