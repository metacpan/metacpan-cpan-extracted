package Reflexive::Event::Data;
{
  $Reflexive::Event::Data::VERSION = '1.122150';
}
use Moose;

#ABSTRACT: Provides an Event subclass that contains the output from a POE::Filter

extends 'Reflex::Event';


has data => (
    is => 'ro',
    isa => 'Any',
);

__PACKAGE__->make_event_cloner();
__PACKAGE__->meta->make_immutable();

1;


=pod

=head1 NAME

Reflexive::Event::Data - Provides an Event subclass that contains the output from a POE::Filter

=head1 VERSION

version 1.122150

=head1 DESCRIPTION

Reflexive::Event::Data is a Reflex::Event subclass that provides a L</data> attribute to contain the actual output from the POE::Filter in use by the Reflexive::Stream::Filtering object. One event is emitted for each data element returned from the Filter. 

=head1 PUBLIC_ATTRIBUTES

=head2 data

    is: ro, isa: Any

This attribute contains whatever is the output from the specific Filter
provided to Reflexive::Stream::Filtering. There should be one of these per item
of output from the filter. Please note that Any means that undef is also valid.

=head1 AUTHOR

Nicholas R. Perez <nperez@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Nicholas R. Perez <nperez@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__
