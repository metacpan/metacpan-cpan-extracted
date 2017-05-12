package MooseX::POE::Meta::Trait;
{
  $MooseX::POE::Meta::Trait::VERSION = '0.215';
}
# ABSTRACT: There be dragons here.
use Moose::Role;

use MooseX::POE::Meta::Method::State;

has events => (
    reader     => 'get_events',
    traits     => ['Array'],
    isa        => 'ArrayRef',
    auto_deref => 1,
    lazy_build => 1,
    builder    => 'default_events',
    handles    => { 'add_event' => ['push'] },
);

sub default_events {
    return [];
}

sub get_state_method_name {
    my ( $self, $name ) = @_;
    return $name if $self->has_method($name);
    return undef;
}

sub add_state_method {
    my ( $self, $name, $method ) = @_;
    if ( $self->has_method($name) ) {
        my $full_name = $self->get_method($name)->fully_qualified_name;
        confess "Cannot add a state method ($name) if a local method ($full_name) is already present";
    }

    $self->add_event($name);
    $self->add_method( $name => $method );
}

after add_role => sub {
    my ( $self, $role ) = @_;

    if ( $role->isa("MooseX::POE::Meta::Role") ) {
        $self->add_event( $role->get_events );
    }
};

1;

__END__
=pod

=head1 NAME

MooseX::POE::Meta::Trait - There be dragons here.

=head1 VERSION

version 0.215

=head1 AUTHORS

=over 4

=item *

Chris Prather <chris@prather.org>

=item *

Ash Berlin <ash@cpan.org>

=item *

Chris Williams <chris@bingosnet.co.uk>

=item *

Yuval (nothingmuch) Kogman

=item *

Torsten Raudssus <torsten@raudssus.de> L<http://www.raudssus.de/>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Chris Prather, Ash Berlin, Chris Williams, Yuval Kogman, Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

