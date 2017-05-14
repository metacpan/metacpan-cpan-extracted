package Myco::Entity::Event;

###############################################################################
# $Id: Event.pm,v 1.5 2006/03/31 19:12:57 sommerb Exp $
#
# See license and copyright near the end of this file.
###############################################################################

=head1 NAME

Myco::Entity::Event - a Myco entity class

=head1 SYNOPSIS

  use Myco;

  # Constructors. See Myco::Entity for more.
  my $obj = Myco::Entity::Event->new;

  # Accessors.
  my $value = $obj->get_fooattrib;
  $obj->set_fooattrib($value);

  $obj->save;
  $obj->destroy;

=head1 DESCRIPTION

An Event logging class for recording information and history for selected
objects

=cut

##############################################################################
# Dependencies
##############################################################################
# Module Dependencies and Compiler Pragma
use warnings;
use strict;
use Myco::Exceptions;
use Myco::Config qw(:evlog);
use WeakRef;
use Myco::Util::DateTime;
use Tangram::Type::Dump::Perl;

##############################################################################
# Constants
##############################################################################
use constant CREATE => 1;
use constant DELETE => 2;
use constant MODIFY => 3;

our @EXPORT = qw(CREATE DELETE MODIFY);

our $kind_map = { &CREATE => 'Create',
                  &DELETE => 'Delete',
                  &MODIFY => 'Modify', };

##############################################################################
# Private Class Variables
##############################################################################
my $event_cache = {};
sub get_event_cache {
    return $event_cache;
}

my $_enabled = EVLOG;
sub enabled {
    return \$_enabled;
}

my $_classes;
for ( @{+EVLOG_CLASSES} ) {
    $_classes->{$_} = undef;
}
sub classes {
    return $_classes;
}

# Must defer import of constants from Myco::Config  until runtime.
# Workaround for mysterious problem when running under mod_perl (?).
#sub init_constants {
#    Myco::Config->import( qw(:evlog) );
#    $_enabled = EVLOG;
#    for ( @{+EVLOG_CLASSES} ) {
#        $_classes->{$_} = undef;
#    }
#}

##############################################################################
# Inheritance & Introspection
##############################################################################
use base qw(Myco::Entity Exporter);
my $md = Myco::Entity::Meta->new
  ( name => __PACKAGE__,
    tangram => { table => 'entity_event' },
  );

##############################################################################
# Function and Closure Prototypes
##############################################################################
# Use this code reference to validate that a real Myco::User object sourced
# the event
my $chk_user_src = sub {
    my $user_src = $ {$_[0]};
    Myco::Exception::DataValidation->throw
        (error => "$user_src is not a Myco::User object")
          unless UNIVERSAL::isa($user_src, 'Myco::User');
};

# Use this code reference to validate the kind of event
my $chk_kind = sub {
    my $kind = $ {$_[0]};
    Myco::Exception::DataValidation->throwMyco::Entity::Test
        (error => "$kind is not a valid kind of event")
          unless defined $kind_map->{$kind};
};

##############################################################################
# Constructor, etc.
##############################################################################

=head1 COMMON ENTITY INTERFACE

Constructor, accessors, and other methods -- as inherited from
Myco::Entity.

=cut

sub new {
    init_constants() unless defined $_enabled;
    my $invocant = shift;
    my $class = ref $invocant || $invocant;
    my %params = @_;
    my $entity = $params{entity};
    my $entity_class = ref $entity;

    # Handle object event
    my $caching;
    if ($entity_class) {
        if ($_enabled && exists $_classes->{$entity_class}) {
            $caching = 1;
        } else {
            return;
        }
    }

    my $event = $class->SUPER::new(@_);

    if ($caching) {
        my $key = "$entity";
        weaken($event->{entity});
        if (exists $event_cache->{$key}) {
            return $event_cache->{$key};
        } else {
            $event_cache->{$key} = $event;
        }
    }
    return $event;
}

##############################################################################
# Attributes & Attribute Accessors / Schema Definition
##############################################################################

=head1 ATTRIBUTES

Attributes may be initially set during object construction (with C<new()>) but
otherwise are accessed solely through accessor methods. Typical usage:

=over 3

=item *  Set attribute value

 $obj->set_attribute($value);

Check functions (see L<Class::Tangram|Class::Tangram>) perform data
validation. If there is any concern that the set method might be called with
invalid data then the call should be wrapped in an C<eval> block to catch
exceptions that would result.

=item *  Get attribute value

 $value = $obj->get_attribute;

=back

A listing of available attributes follows:

=head2 kind

 type: int

The kind of the event. Could be 'Create', 'Delete', or 'Modify'

=cut

my %kind_map = %$kind_map;
$md->add_attribute( name => 'kind',
                    type => 'int',
                    values => [ keys %kind_map ],
                    value_labels => { %kind_map },
                    tangram_options => { check_func => $chk_kind, },
                  );

=head2 state

 type: perl_dump

A string dump of the Entity at time of Event creation.

=cut

$md->add_attribute( name => 'state',
                    type => 'perl_dump',
                    tangram_options => { sql => 'TEXT',
                                         col => 'state' },
                  );



=head2 entity_id

 type: int

The Tangram ID for the entity.

=cut

$md->add_attribute( name => 'entity_id',
                    type => 'int', );



=head2 user_src

 type: ref

The Myco::User object that created (sourced) the entity.

=cut

# NOTE TO SELF: myco-deploy script was puking on the attribute name: 'user'
$md->add_attribute( name => 'user_src',
                    type => 'ref',
                    tangram_options => { check_func => $chk_user_src,
                                         class => 'Myco::User', },
                  );



=head2 entity_class

 type: string

The name of the class of the entity.

=cut

$md->add_attribute( name => 'entity_class',
                    type => 'string', );



=head2 date

 type: rawdate

The date the event was occured.

=cut

$md->add_attribute( name => 'date',
                    type => 'rawdate',
                    tangram_options =>
                    { sql => 'DATE',
                      init_default => sub {
                          Myco::Util::DateTime->date('YYYY-MM-DD') },
                    },
                  );



=head2 entity

 type: transient

The entity object about which an event is being recorded. Intitalized with a
reference to it.

=cut

$md->add_attribute( name => 'entity',
                    type => 'transient', );

##############################################################################
# Methods
##############################################################################

sub flush_event {
    my ($class, $entity) = @_;

    my $key = "$entity";
    if ( exists $event_cache->{$key} ) {
        my $event = $event_cache->{$key};

        my $ent_id = $entity->id;
        $event->set_entity_id( $ent_id ) if $ent_id;

        my $id = Myco->insert($event);
        delete $event_cache->{$key} if exists $event_cache->{$key};
        Myco->unload($event);
        return $id;
    }
}

# Method to build up a cache of events.
sub build_event_cache {
    my ($self, $attr, $val) = @_;
    # Exit if we're trying to create an event for an event object
    return if ref $self eq 'Myco::Entity::Event';

    # Treat $val specially if $val is a reference. Just stringify it for now.
    $val = "$val" if ref $val ne '';

    my $event;
    my $key = "$self";
#    if ( exists $event_cache->{$key} ) {
#        $event_cache->{$key}->{$attr} = $val;
#    } else {
#        $event = Myco::Entity::Event->new;
#        $event_cache->{"$event"}->{$attr} = $val;
#        $event_cache->{"$event"}->{$attr} = $val;
#        $event = $self;
#    }

    # Stringify $event for use as a hash key - we'll probably add attrs to it
}

##############################################################################
# Object Schema Activation and Metadata Finalization
##############################################################################
$md->activate_class;

1;
__END__
