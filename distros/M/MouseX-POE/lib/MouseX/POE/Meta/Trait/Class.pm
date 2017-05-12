package MouseX::POE::Meta::Trait::Class;
$MouseX::POE::Meta::Trait::Class::VERSION = '0.216';
# ABSTRACT: No achmed inside
use Mouse::Role;

with qw(MouseX::POE::Meta::Trait);

# TODO: subclass events to be a hashref that maps the event to the method
# so we can support on_ events

around default_events => sub {
    my ( $next, $self ) = @_;
    my $events = $next->($self);
    push @$events, grep { s/^on_(\w+)/$1/; } $self->get_method_list;
    return $events;
};


around get_state_method_name => sub {
    my ( $next, $self, $name ) = @_;
    return 'on_' . $name if $self->has_method( 'on_' . $name );
    return $next->( $self, $name );
};

sub get_all_events {
    my ($self) = @_;
    my $wanted_role = 'MouseX::POE::Meta::Trait';

    # This horrible grep can be removed once Mouse gets more metacircular.
    # Currently Mouse::Meta::Class->meta isn't a MMC. It should be, and it
    # should also be a Mouse::Object so does works on it.
    my %events
        = map {
        my $m = $_;
        map { $_ => $m->get_state_method_name($_) } $m->get_events
        }
        grep {
        $_->meta->can('does_role') && $_->meta->does_role($wanted_role)
        }
        map { $_->meta } $self->linearized_isa;
    return %events;
}

no Mouse::Role;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MouseX::POE::Meta::Trait::Class - No achmed inside

=head1 VERSION

version 0.216

=head1 METHODS

=head2 get_all_events

=begin comment




=end comment

around add_role => sub {
    my ( $next, $self, $role ) = @_;
    $next->( $self, $role );

    if (   $role->meta->can('does_role')
        && $role->meta->does_role("MouseX::POE::Meta::Trait") ) {
        $self->add_event( $role->get_events );
    }
};

=head1 DEPENDENCIES

Mouse::Role

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
