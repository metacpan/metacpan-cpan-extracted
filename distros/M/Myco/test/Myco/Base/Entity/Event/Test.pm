package Myco::Base::Entity::Event::Test;

###############################################################################
# $Id: Test.pm,v 1.1.1.1 2004/11/22 19:16:03 owensc Exp $
#
# See license and copyright near the end of this file.
###############################################################################

=head1 NAME

Myco::Base::Entity::Event::Test -

unit tests for features of Myco::Base::Entity::Event

=head1 VERSION

$Revision: 1.1.1.1 $

=cut

our $VERSION = (qw$Revision: 1.1.1.1 $ )[-1];

=head1 DATE

$Date: 2004/11/22 19:16:03 $

=head1 SYNOPSIS

 cd $MYCO_DISTRIB/bin
 # run tests.  '-m': test just in-memory behavior
 ./testrun [-m] Myco::Base::Entity::Event::Test
 # run tests, GUI style
 ./tktestrun Myco::Base::Entity::Event::Test

=head1 DESCRIPTION

Unit tests for features of Myco::Base::Entity::Event.

=cut

### Inheritance
use base qw(Test::Unit::TestCase Myco::Test::EntityTest);

### Module Dependencies and Compiler Pragma
use Myco::Base::Entity::Event;
use Myco::Base::Entity::SampleEntity;
use Class::Tangram;
use Data::Dumper;
use strict;
use warnings;
use Myco::Config qw(:evlog);
use WeakRef;

### Class Data

# This class tests features of:
my $class = 'Myco::Base::Entity::Event';
my $logging_state;
# Names of sample class packages used by these unit tests
use constant ENTITY => 'Myco::Base::Entity::SampleEntity';

# It may be helpful to number tests... use testrun's -d flag to view
#   test-specific debug output (see example tests, testrun)
use constant DEBUG => $ENV{MYCO_TEST_DEBUG} || 0;

##############################################################################
#  Test Control Parameters
##############################################################################
my %test_parameters =
  (
   # A scalar attribute that can be used for testing... set to undef
   #    to disable related tests
   simple_accessor => 'entity_id',

   skip_persistence => 1,     # skip persistence tests?  (defaults to false)
   standalone => 0,           # don't compile Myco entity classes

   # Default attribute values for use when constructing objects
   #    Needed for any 'required' attributes
   defaults =>
       {
#	name => 'a value',
       },
  );

##############################################################################
# Hooks into Myco test framework.
##############################################################################

sub new {
    my $self = shift;
    # create fixture object and handle related needs (esp. DB connection)
    my $fixture = $self->init_fixture(@_);
    $fixture->set_class($class);
    $fixture->set_params(\%test_parameters);
    return $fixture;
}

sub set_up {
    my $test = shift;
    $test->help_set_up(@_);
}

sub tear_down {
    my $test = shift;
    $test->help_tear_down(@_);
}


##############################################################################
###
### Unit Tests for Myco::Base::Entity::Event
###
##############################################################################
#   Tests of Setters and Getters with check functions
##############################################################################
#none

sub test_1_kind {
    my $test = shift;
    return if $test->should_skip;

    my $event = $test->new_testable_entity;

    # Check that check function works
    eval {
        $event->set_kind(5); # an invalid value
    };
    $test->assert( $@, 'Event Kind check didn\'t function work' );

    $test->destroy_upon_cleanup($event);
}


##############################################################################
#   Tests of In-Memory Behavior
##############################################################################

sub test_4_constant_export {
    my $test = shift;
    return if $test->should_skip;
    $test->assert( eval { CREATE } == 1, 'Create constant available' );
}

sub test_5_log_constant {
    my $test = shift;
    return if $test->should_skip;
    my $evlog = eval { EVLOG };
    $test->assert( ! $@, 'evlog came through' );
    $test->assert( defined $evlog && $evlog ne '', '$evlog is not empty' );
}

sub test_event_log_controls {
    my $test = shift;
    return if $test->should_skip;

    my $event = $test->new_testable_entity;
    my $enabled = eval { $event->enabled; };
    $test->assert( ! $@, 'logging enabled' );
    $test->assert( ref $enabled eq 'SCALAR', '$enabled is a scalar ref' );

    my $classes = eval { $event->classes; };
    $test->assert( ! $@, 'logging classes present!' );
    $test->assert( ref $classes eq 'HASH', '$classes is a hash ref' );
}

##############################################################################
#   Tests of Persistence Behavior
##############################################################################

sub test_6_overriden_new {
    my $test = shift;
    return if $test->should_skip;

    my $event_0 = eval { $class->new; };
    $test->assert( ! $@, '->new works' );
    $test->assert( defined $event_0, 'Got $event_0' );

    my $entity_0 = ENTITY->new( name => 'foo' );
    $event_0 = $class->new( entity => $entity_0, kind => CREATE );
    $test->assert( ! exists $class->get_event_cache->{"$entity_0"},
                   'Event wasn\'t cached' );

    $test->logging_on(ENTITY);
    $event_0 = $class->new( entity => $entity_0, kind => CREATE );
    $test->assert( exists $class->get_event_cache->{"$entity_0"},
                   'Event was cached' );

    $test->assert( isweak($event_0->{entity}), 'Reference is Weak!' );

    my $entity = ENTITY->new;
    # Get the event cache
    my $cache = $class->get_event_cache;
    print Dumper($cache) if DEBUG;
    $test->assert( my $event = $cache->{"$entity"},'Got a new entity' );

    # Save event and manually clear the cache, then reload it and check cache
    my $id = $event->save;
    %$cache = ();
    Myco->unload($event);
    $test->assert( my $resurected = Myco->load($id), 'Resurected the event' );

    $test->assert( (keys %$cache) == 0, '$cache is still empty' );

    $test->logging_off(ENTITY);
    $test->destroy_upon_cleanup($resurected);
}

sub test_7_flush_event_cache {
    my $test = shift;
    return if $test->should_skip;

    $test->logging_on(ENTITY);

    # Case:  Unsaved entity, force event save

    my $entity = ENTITY->new(name => 'foo');
    my $event = $class->get_event_cache->{"$entity"};

    my $key = "$entity";
    # This is normally called only via entity save
    my $ev_id = $class->flush_event($entity);
    $test->assert( ! Myco->is_transient($event), '$event is not transient' );
    $test->assert( ! exists $event->get_event_cache->{"$entity"},
                   'Event cache did flush' );
    $test->assert( $ev_id, 'Event id returned' );
    ($event) = Myco->load($ev_id);
    $test->assert( ref $event eq $class, "$event is a $class object" );

    # Case:  Saved entity

    my $entity2 = ENTITY->new(name => 'foo');
    my $event2 = $class->get_event_cache->{"$entity2"};
    $key = "$entity2";
    my $ent_id = $entity2->save;
    $test->assert( ! Myco->is_transient($event2), '$event2 is not transient' );
    $test->assert( ! exists $event->get_event_cache->{"$entity2"},
                   'Event cache did flush' );
    my $ev_r = Myco->remote( $class );
    my ($resurected) = Myco->select($ev_r, $ev_r->{entity_id} == $ent_id);
    $test->assert( ref $resurected eq $class, 'Event resurected' );

    $test->logging_off(ENTITY);
    $test->destroy_upon_cleanup( $resurected, $entity2, $event );
}

sub _test_8_flush_on_destroy {
    my $test = shift;
    return if $test->should_skip;

    $test->logging_on(ENTITY);

    my $key;
    {
        my $entity = ENTITY->new(name => 'foo');
        $key = "$entity";
        $test->assert( exists $class->get_event_cache->{$key},
                       'Event was cached' );
    }
    $test->assert( ! exists $class->get_event_cache->{$key},
                   'Event was removed during entity garbage collection' );
    $test->logging_off(ENTITY);

}

sub test_9_save_entity {
    my $test = shift;
    return if $test->should_skip;

    # Instantiate new event for $entity, test &flush_event_cache
    $test->logging_on(ENTITY);
    my $entity = ENTITY->new(name => 'foo');
    my $event = $class->get_event_cache->{"$entity"};
    my $ent_id = $entity->save;
    $test->assert( ! exists $class->get_event_cache->{"$entity"},
                   'Event flushed from cache' );

    my $ev_r = Myco->remote( $class );
    my ($resurected) = Myco->select($ev_r, $ev_r->{entity_id} == $ent_id);
    $test->assert( ref $resurected eq $class, 'Event resurected' );

    $test->logging_off(ENTITY);
    $test->destroy_upon_cleanup( $resurected, $entity );
}


sub test_10_erase_entity {
    my $test = shift;
    return if $test->should_skip;

    $test->logging_on(ENTITY);
    my $evr = Myco->remote( $class );
    my $create_event;
    my ($id, $key);
    {
        my $entity = ENTITY->new(name => 'foo');
        $key = "$entity";
        $id = $entity->save;
        ($create_event) = Myco->select( $evr, $evr->{entity_id} == $id
                                           && $evr->{kind} == CREATE );
        $entity->destroy;
    }
    my ($erase_event) = Myco->select( $evr, $evr->{entity_id} == $id
                                      && $evr->{kind} == DELETE );

    $test->assert( ref $erase_event eq $class, 'found DELETE event in db' );

    $test->assert( ! exists $class->get_event_cache->{$key},
                   'DELETE event not cached' );

    $test->logging_off(ENTITY);
    $test->destroy_upon_cleanup( $erase_event, $create_event );
}

sub test_11_modify_entity {
    my $test = shift;
    return;#if $test->should_skip;

    $test->logging_off(ENTITY);
}

###############################################################################
# Helper Methods
sub logging_on {
    my ($self, $entity) = @_;
    $logging_state = $ {$class->enabled};
    $ {$class->enabled} = 1;
    my $classes = $class->classes;
    $classes->{$entity} = undef;
}

sub logging_off {
    my ($self, $entity) = @_;
    $ {$class->enabled} = $logging_state;
    my $classes = $class->classes;
    delete $classes->{$entity};
}

1;
__END__
