package StateML::State ;

use strict ;
use Carp ;
use base qw(StateML::Object ) ;

=head1 DESCRIPTION

=head1 METHODS

TODO: Complete the docs.

See L<StateML::Object|StateML::Object> for methods available to all objects.

=over

=cut

sub new {
    return shift()->SUPER::new(
        ENTRY_HANDLERS => [],
        EXIT_HANDLERS  => [],
        @_
    ) ;
}


sub handlers {
    my $self = shift ;
    $self->{API} = shift if @_ ;
    return $self->{API} ;
}


sub number {
    my $self = shift ;
    confess "Cannot set a state's number." if @_ ;
    return $self->{ORDER} ;
}


sub description {
    my $self = shift ;
    $self->{DESCRIPTION} = shift if @_ ;
    return $self->{DESCRIPTION};
}


sub entry_handlers {
    my $self = shift ;
    my $all = $self->machine->state_by_id( "#ALL" ) ;
    return @{$self->{ENTRY_HANDLERS}}, $all ? @{$all->{ENTRY_HANDLERS}} : () ;
}


sub exit_handlers {
    my $self = shift ;
    my $all = $self->machine->state_by_id( "#ALL" ) ;
    return $all ? @{$all->{EXIT_HANDLERS}} : (), @{$self->{EXIT_HANDLERS}} ;
}


sub _set_number {
    my $self = shift ;
    $self->{ORDER} = shift ;
    return ;
}

=item arcs_from

Returns a list of arcs out of this state.

This is a convenience method for template generation.

=cut

sub arcs_from {
    my $self = shift;
    my $id = $self->id;
    grep $_->from eq $id, $self->machine->arcs;
}

=item arcs_to

Returns a list of arcs into this state.

This is a convenience method for template generation.

=cut

sub arcs_to {
    my $self = shift;
    my $id = $self->id;
    grep $_->to eq $id, $self->machine->arcs;
}

=back

=head1 LIMITATIONS

=head1 COPYRIGHT

    Copyright 2003, R. Barrie Slaymaker, Jr., All Rights Reserved

=head1 LICENSE

You may use this module under the terms of the BSD, Artistic, or GPL licenses,
any version.

=head1 AUTHOR

Barrie Slaymaker <barries@slaysys.com>

=cut

1 ;
