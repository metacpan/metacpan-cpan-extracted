package TAEB::World::MonsterTracker;
use TAEB::OO;

# Monster tracking
#
# Monsters are visible and have visible state.  Unfortunately, they also
# have hidden and mostly-hidden variables - mpeaceful, movement, etc. We
# want to learn about these hidden variables by watching monsters, but
# how do we know which past measurements are applicable now?
#
# Obviously, this is an inexact science, and monster tracking never
# claims to give an exact answer, instead quoting confidence figures.
#
# The easy case: threads
#
# Sometimes we see the same monster twice on consequent steps.  Each time
# the monster tracker updates, we see that some monsters are in similar
# places to similar monsters last turn, and we can declare the two monsters
# equivalent with extremely high confidence.  A chain of monster observations
# linked in this way are called a 'thread', and is represented by an object
# of type TAEB::World::Monster.
#
# The hard way: monster pools
#
# A monster left FOV and is no longer a current thread.  We see a new
# monster.  What do we do?  When monsters leave FOV, they enter a pool
# of unaccounted-for threads.  New monsters are compared against the
# pool.  They do not continue the thread, but they get a backlink
# attribute, containing one or more pairs of old thread and confidence.
#
# One monster tracker exists per level.
#

# More on monsters
#
# Each monster has a number of hidden and not-so-hidden variables,
# which are modeled inside TAEB as attributes.  There are two kinds
# of such attributes.  Observations are made anew every turn, and
# reset on update to be set by occurences in the turn; examples of
# observations are last_move and just_attacked_us.  Hidden variables
# are kept between turns, but carry multiple values, each associated
# with a confidence factor.  Each turn, before resetting observations,
# we use code to incorporate the values of observations into our
# hidden-variable model.
#
# Where do we get this code?  Observation and HiddenVar are Moose
# traits, and carry code meta-attributes.


use overload %TAEB::Meta::Overload::default;

has level => (
    isa      => 'TAEB::World::Level',
    weak_ref => 1,
);

has visible => (
    isa    => 'ArrayRef[TAEB::World::Monster]',
);

has pool => (
    isa    => 'ArrayRef[TAEB::World::Monster]',
);

# This function is the meat of the monster tracker.  It examines the
# current state, compares each monster to the visibles, updates
# threads, and moves missing monsters into the pool.  New monsters
# are drawn from the pool per above.

sub update {
    my ($self) = @_;

    # Need to check for telepathy, so that popping a blindfold won't
    # break all our mindless monster threads

    # Test monsters against $self->visible; add new monsters, delete
    # old ones

    # Go through $self->visible and add backlinks for old monsters
    # Subtract out confidence from a pool monster's confidence_left
    # Delete when it reaches 0.2 or so

    # Update $self->level->at(X,Y)->monster
}

# Ideas for other methods: do we remember a monster near here?

__PACKAGE__->meta->make_immutable;
no TAEB::OO;

1;

