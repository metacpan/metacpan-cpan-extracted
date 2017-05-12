package TAEB::Action;
use TAEB::OO;
use Module::Pluggable
    search_path => 'TAEB::Action',
    require     => 1,
    sub_name    => 'actions';

has aborted => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

has starting_tile => (
    is      => 'ro',
    isa     => 'TAEB::World::Tile',
    default => sub { TAEB->current_tile },
);

=head2 command

This is the basic command for the action. For example, C<E> for engraving, and
C<#pray> for praying.

=cut

sub command {
    my $class = blessed($_[0]) || $_[0];
    confess "$class must defined a 'command' method.";
}

=head2 run

This is what is called to begin the NetHack command. Usually you don't override
this. Your command should define prompt handlers (C<respond_*> methods) to
continue interaction.

=cut

sub run { shift->command }

=head2 post_responses

This is called just after all responses will be queried, but before the
cartographer, senses, messages, etc are done for this step.

=cut

sub post_responses { }

=head2 done

This is called just before the action is freed, just before the next command
is run.

=cut

sub done { }

=head2 new_action Str, Args => Action

This will create a new action with the specified name and arguments. The name
is typically the package name in lower case.

=cut

sub new_action {
    my $self = shift;
    my $name = shift;

    # guess case if all lowercase, otherwise use whatever we've got
    if ($name eq lc $name) {
        $name = ucfirst $name;
    }

    my $package = "TAEB::Action::$name";
    return $package->new(@_);
}

=head2 name

Returns the name of this action object.

=cut

sub name {
    my $self = shift;

    # because Moose may rebless our instance, we need to look at the
    # inheritance hierarchy for something that resembles TAEB::Action::Foo
    for my $class ($self->meta->linearized_isa) {
        return $1 if $class =~ m{^TAEB::Action::(\w+)$};
    }

    TAEB->log->action("Unable to get the action name of $self: " . join(', ', $self->meta->linearized_isa), level => 'warning');
    return;
}

=head2 action_names

Returns a list of action names (Search, Melee, Eat, etc)

=cut

sub action_names {
    my $self = shift;

    return map  { (my $class = $_) =~ s/^TAEB::Action:://; $class }
           grep { $_->isa('TAEB::Action') }
           sort $self->actions;
}

__PACKAGE__->meta->make_immutable;
no TAEB::OO;

# force loading of all the actions for compile errors etc
__PACKAGE__->actions;


1;

