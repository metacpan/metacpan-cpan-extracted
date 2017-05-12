package SPOPS;

# $Id: SPOPS.pm,v 3.39 2004/06/02 00:48:20 lachoy Exp $

use strict;
use base  qw( Exporter ); # Class::Observable
use Data::Dumper    qw( Dumper );
use Log::Log4perl   qw( get_logger );
use SPOPS::ClassFactory::DefaultBehavior;
use SPOPS::Exception;
use SPOPS::Tie      qw( IDX_CHANGE IDX_SAVE IDX_CHECK_FIELDS IDX_LAZY_LOADED );
use SPOPS::Tie::StrictField;
use SPOPS::Secure   qw( SEC_LEVEL_WRITE );

my $log = get_logger();

$SPOPS::AUTOLOAD  = '';
$SPOPS::VERSION   = '0.87';
$SPOPS::Revision  = sprintf("%d.%02d", q$Revision: 3.39 $ =~ /(\d+)\.(\d+)/);

# DEPRECATED

sub DEBUG                { return 1 }
sub set_global_debug     { warn "Global debugging not supported -- use log4perl instead!\n" }

my ( $USE_CACHE );
sub USE_CACHE            { return $USE_CACHE }
sub set_global_use_cache { $USE_CACHE = $_[1] }

@SPOPS::EXPORT_OK = qw( _w _wm DEBUG );

require SPOPS::Utility;

########################################
# CLASS CONFIGURATION
########################################

# These are default configuration behaviors -- all SPOPS classes have
# the option of using them or of halting behavior before they're
# called

sub behavior_factory {
    my ( $class ) = @_;

    $log->is_info &&
        $log->info( "Installing SPOPS default behaviors for ($class)" );
    return { manipulate_configuration =>
                    \&SPOPS::ClassFactory::DefaultBehavior::conf_modify_config,
             read_code                =>
                    \&SPOPS::ClassFactory::DefaultBehavior::conf_read_code,
             id_method                =>
                    \&SPOPS::ClassFactory::DefaultBehavior::conf_id_method,
             has_a                    =>
                    \&SPOPS::ClassFactory::DefaultBehavior::conf_relate_hasa,
             fetch_by                 =>
                    \&SPOPS::ClassFactory::DefaultBehavior::conf_relate_fetchby,
             add_rule                 =>
                    \&SPOPS::ClassFactory::DefaultBehavior::conf_add_rules, };
}


########################################
# CLASS INITIALIZATION
########################################

# Subclasses should almost certainly define some behavior here by
# overriding this method

sub class_initialize {}


########################################
# OBJECT CREATION/DESTRUCTION
########################################

# Constructor

sub new {
    my ( $pkg, $p ) = @_;
    my $class = ref $pkg || $pkg;
    my $params = {};
    my $tie_class = 'SPOPS::Tie';

    my $CONFIG = $class->CONFIG;

    # Setup field checking if specified

    if ( $CONFIG->{strict_field} || $p->{strict_field} ) {
        my $fields = $class->field;
        if ( keys %{ $fields } ) {
            $params->{field} = [ keys %{ $fields } ];
            $tie_class = 'SPOPS::Tie::StrictField'
        }
    }

    # Setup lazy loading if specified

    if ( ref $CONFIG->{column_group} eq 'HASH' and
         keys %{ $CONFIG->{column_group} } ) {
        $params->{is_lazy_load}  = 1;
        $params->{lazy_load_sub} = $class->get_lazy_load_sub;
    }

    # Setup field mapping if specified

    if ( ref $CONFIG->{field_map} eq 'HASH' and
         scalar keys %{ $CONFIG->{field_map} } ) {
        $params->{is_field_map} = 1;
        $params->{field_map} = \%{ $CONFIG->{field_map} };
    }

    # Setup multivalue fields if specified

    my $multivalue_ref = ref $CONFIG->{multivalue};
    if ( $multivalue_ref eq 'HASH' or $multivalue_ref eq 'ARRAY' ) {
        my $num = ( $multivalue_ref eq 'HASH' )
                    ? scalar keys %{ $CONFIG->{multivalue} }
                    : scalar @{ $CONFIG->{multivalue} };
        if ( $num > 0 ) {
            $params->{is_multivalue} = 1;
            $params->{multivalue} = ( $multivalue_ref eq 'HASH' )
                                      ? \%{ $CONFIG->{multivalue} }
                                      : \@{ $CONFIG->{multivalue} };
        }
    }

    $params->{is_lazy_load} ||= 0;
    $params->{is_field_map} ||= 0;

    $log->is_info &&
        $log->info( "Creating new object of class ($class) with tie class ",
                    "($tie_class); lazy loading ($params->{is_lazy_load});",
                    "field mapping ($params->{is_field_map})" );

    my ( %data );
    my $internal = tie %data, $tie_class, $class, $params;
    $log->is_debug &&
        $log->debug( "Internal tie structure of new object: ", Dumper( $internal ) );
    my $self = bless( \%data, $class );

    # Set defaults if set, unless NOT specified

    my $defaults = $p->{default_values} || $CONFIG->{default_values};
    if ( ref $defaults eq 'HASH' and ! $p->{skip_default_values} ) {
        foreach my $field ( keys %{ $defaults } ) {
            if ( ref $defaults->{ $field } eq 'HASH' ) {
                my $default_class  = $defaults->{ $field }{class};
                my $default_method = $defaults->{ $field }{method};
                unless ( $default_class and $default_method ) {
                    $log->warn( "Cannot set default for ($field) without a class ",
                                "AND method being defined." );
                    next;
                }
                $self->{ $field } = eval { $default_class->$default_method( $field ) };
                if ( $@ ) {
                    $log->warn( "Cannot set default for ($field) in ($class) using",
                           "($default_class) ($default_method): $@" );
                }
            }
            elsif ( $defaults->{ $field } eq 'NOW' ) {
                $self->{ $field } = SPOPS::Utility->now;
            }
            else {
                $self->{ $field } = $defaults->{ $field };
            }
        }
    }

    $self->initialize( $p );
    $self->has_change;
    $self->clear_save;
    $self->initialize_custom( $p );
    return $self;
}


sub DESTROY {
    my ( $self ) = @_;

    # Need to check that $log exists because sometimes it gets
    # destroyed before our SPOPS objects do

    if ( $log ) {
        $log->is_debug &&
            $log->debug( "Destroying SPOPS object '", ref( $self ), "' ID: " .
                         "'", $self->id, "' at time: ", scalar localtime );
    }
}


# Create a new object from an old one, allowing any passed-in
# values to override the ones from the old object

sub clone {
    my ( $self, $p ) = @_;
    my $class = $p->{_class} || ref $self;
    $log->is_info &&
        $log->info( "Cloning new object of class '$class' from old ",
                    "object of class '", ref( $self ), "'" );
    my %initial_data = ();

    my $id_field = $class->id_field;
    if ( $id_field ) {
        $initial_data{ $id_field } = $p->{ $id_field } || $p->{id};
    }

    my $fields = $self->_get_definitive_fields;
    foreach my $field ( @{ $fields } ) {
        next if ( $id_field and $field eq $id_field );
        $initial_data{ $field } =
            exists $p->{ $field } ? $p->{ $field } : $self->{ $field };
    }

    return $class->new({ %initial_data, skip_default_values => 1 });
}


# Simple initialization: subclasses can override for
# field validation or whatever.

sub initialize {
    my ( $self, $p ) = @_;
    $p ||= {};

    # Creating a new object, all fields are set to 'loaded' so we don't
    # try to lazy-load a field when the object hasn't even been saved

    $self->set_all_loaded();

    # We allow the user to substitute id => value instead for the
    # specific fieldname.

    $self->id( $p->{id} )  if ( $p->{id} );
    #$p->{ $self->id_field } ||= $p->{id};

    # Go through the data passed in and set data for fields used by
    # this class

    my $class_fields = $self->field || {};
    while ( my ( $field, $value ) = each %{ $p } ) {
        next unless ( $class_fields->{ $field } );
        $self->{ $field } = $value;
    }
}

# subclasses can override...
sub initialize_custom { return }

########################################
# CONFIGURATION
########################################

# If a class doesn't define a config method then something is seriously wrong

sub CONFIG {
    require Carp;
    Carp::croak "SPOPS class not created properly, since CONFIG being called ",
                "from SPOPS.pm rather than your object class.";
}


# Some default configuration methods that all SPOPS classes use

sub field               { return $_[0]->CONFIG->{field} || {}              }
sub field_list          { return $_[0]->CONFIG->{field_list} || []         }
sub field_raw           { return $_[0]->CONFIG->{field_raw} || []          }
sub field_all_map {
    return { map { $_ => 1 } ( @{ $_[0]->field_list }, @{ $_[0]->field_raw } ) }
}
sub id_field            { return $_[0]->CONFIG->{id_field}                 }
sub creation_security   { return $_[0]->CONFIG->{creation_security} || {}  }
sub no_security         { return $_[0]->CONFIG->{no_security}              }

# if 'field_raw' defined use that, otherwise just return 'field_list'

sub _get_definitive_fields {
    my ( $self ) = @_;
    my $fields = $self->field_raw;
    unless ( ref $fields eq 'ARRAY' and scalar @{ $fields } > 0 ) {
        $fields = $self->field_list;
    }
    return $fields;
}

########################################
# STORABLE SERIALIZATION

sub store {
    my ( $self, @params ) = @_;
    die "Not an object!" unless ( ref $self and $self->isa( 'SPOPS' ) );
    require Storable;
    return Storable::store( $self, @params );
}

sub nstore {
    my ( $self, @params ) = @_;
    die "Not an object!" unless ( ref $self and $self->isa( 'SPOPS' ) );
    require Storable;
    return Storable::nstore( $self, @params );
}

sub retrieve {
    my ( $class, @params ) = @_;
    require Storable;
    return Storable::retrieve( @params );
}

sub fd_retrieve {
    my ( $class, @params ) = @_;
    require Storable;
    return Storable::fd_retrieve( @params );
}


########################################
# RULESET METHODS
########################################

# So all SPOPS classes have a ruleset_add in their lineage

sub ruleset_add     { return __PACKAGE__ }
sub ruleset_factory {}

# These are actions to do before/after a fetch, save and remove; note
# that overridden methods must return a 1 on success or the
# fetch/save/remove will fail; this allows any of a number of rules to
# short-circuit an operation; see RULESETS in POD
#
# clarification: $_[0] in the following can be *either* a class or an
# object; $_[1] is the (optional) hashref passed as the only argument

sub pre_fetch_action    { return $_[0]->ruleset_process_action( 'pre_fetch_action', $_[1]   ) }
sub post_fetch_action   { return $_[0]->ruleset_process_action( 'post_fetch_action', $_[1] ) }
sub pre_save_action     { return $_[0]->ruleset_process_action( 'pre_save_action', $_[1] ) }
sub post_save_action    { return $_[0]->ruleset_process_action( 'post_save_action', $_[1] ) }
sub pre_remove_action   { return $_[0]->ruleset_process_action( 'pre_remove_action', $_[1] ) }
sub post_remove_action  { return $_[0]->ruleset_process_action( 'post_remove_action', $_[1] ) }

#sub pre_fetch_action    { return shift->notify_observers( 'pre_fetch_action', @_   ) }
#sub post_fetch_action   { return shift->notify_observers( 'post_fetch_action', @_ ) }
#sub pre_save_action     { return shift->notify_observers( 'pre_save_action', @_ ) }
#sub post_save_action    { return shift->notify_observers( 'post_save_action', @_ ) }
#sub pre_remove_action   { return shift->notify_observers( 'pre_remove_action', @_ ) }
#sub post_remove_action  { return shift->notify_observers( 'post_remove_action', @_ ) }

# Go through all of the subroutines found in a particular class
# relating to a particular action

sub ruleset_process_action {
    my ( $item, $action, $p ) = @_;
    #die "This method is no longer used. Please see SPOPS::Manual::ObjectRules.\n";

    my $class = ref $item || $item;

    $action = lc $action;
    $log->is_info &&
        $log->info( "Trying to process $action for a '$class' object" );

    # Grab the ruleset table for this class and immediately
    # return if the list of rules to apply for this action is empty

    my $rs_table = $item->RULESET;
    unless ( ref $rs_table->{ $action } eq 'ARRAY'
                 and scalar @{ $rs_table->{ $action } } > 0 ) {
        $log->is_debug &&
            $log->debug( "No rules to process for [$action]" );
        return 1;
    }
    $log->is_info &&
        $log->info( "Ruleset exists in class." );

    # Cycle through the rules -- the only return value can be true or false,
    # and false short-circuits the entire operation

    my $count_rules = 0;
    foreach my $rule_sub ( @{ $rs_table->{ $action } } ) {
        $count_rules++;
        unless ( $rule_sub->( $item, $p ) ) {
            $log->warn( "Rule $count_rules of '$action' for class '$class' failed" );
            return undef;
        }
    }
    $log->is_info &&
        $log->info( "$action processed ($count_rules rules successful) without error" );
    return 1;
}


########################################
# SERIALIZATION
########################################

# Routines for subclases to override

sub save        { die "Subclass must implement save()\n" }
sub fetch       { die "Subclass must implement fetch()\n" }
sub remove      { die "Subclass must implement remove()\n" }
sub log_action  { return 1 }

# Define methods for implementors to override to do something in case
# a fetch / save / remove fails

sub fail_fetch  {}
sub fail_save   {}
sub fail_remove {}


########################################
# SERIALIZATION SUPPORT
########################################

sub fetch_determine_limit { return SPOPS::Utility->determine_limit( $_[1] ) }


########################################
# LAZY LOADING
########################################

sub get_lazy_load_sub { return \&perform_lazy_load }
sub perform_lazy_load { return undef }

sub is_loaded         { return tied( %{ $_[0] } )->{ IDX_LAZY_LOADED() }{ lc $_[1] } }

sub set_loaded        { return tied( %{ $_[0] } )->{ IDX_LAZY_LOADED() }{ lc $_[1] }++ }

sub set_all_loaded {
    my ( $self ) = @_;
    $log->is_info &&
        $log->info( "Setting all fields to loaded for object class", ref $self );
    $self->set_loaded( $_ ) for ( @{ $self->field_list } );
}

sub clear_loaded { tied( %{ $_[0] } )->{ IDX_LAZY_LOADED() }{ lc $_[1] } = undef }

sub clear_all_loaded {
    $log->is_info &&
        $log->info( "Clearing all fields to unloaded for object class", ref $_[0] );
    tied( %{ $_[0] } )->{ IDX_LAZY_LOADED() } = {};
}


########################################
# FIELD CHECKING
########################################

# Is this object doing field checking?

sub is_checking_fields { return tied( %{ $_[0] } )->{ IDX_CHECK_FIELDS() }; }


########################################
# MODIFICATION STATE
########################################

# Track whether this object has changed (keep 'changed()' for backward
# compatibility)

sub changed      { is_changed( @_ ) }
sub is_changed   { return $_[0]->{ IDX_CHANGE() } }
sub has_change   { $_[0]->{ IDX_CHANGE() } = 1 }
sub clear_change { $_[0]->{ IDX_CHANGE() } = 0 }


########################################
# SERIALIZATION STATE
########################################

# Track whether this object has been saved (keep 'saved()' for
# backward compatibility)

sub saved        { is_saved( @_ ) }
sub is_saved     { return $_[0]->{ IDX_SAVE() } }
sub has_save     { $_[0]->{ IDX_SAVE() } = 1 }
sub clear_save   { $_[0]->{ IDX_SAVE() } = 0 }


########################################
# OBJECT INFORMATION
########################################

# Return the name of this object (what type it is), title of the
# object and url (in a hashref) to be used to make a link, or whatnot.

sub object_description {
    my ( $self ) = @_;
    my $object_type = $self->CONFIG->{object_name};
    my $title_info  = $self->CONFIG->{name};
    my $title = '';
    if ( ref $title_info eq 'CODE' ) {
        warn "NOTE: Setting a coderef for the 'name' configuration ",
             "key in [$object_type] is deprecated. It will be phased ",
             "out.\n";
        $title = eval { $title_info->( $self ) };
    }
    elsif ( exists $self->{ $title_info } ) {
        $title = $self->{ $title_info };
    }
    else {
        $title = eval { $self->$title_info() };
    }
    $title ||= 'Cannot find name';
    my $oid       = $self->id;
    my $id_field  = $self->id_field;
    my $link_info = $self->CONFIG->{display};
    my ( $url, $url_edit );
    if ( $link_info->{url} ) {
        $url       = "$link_info->{url}?" . $id_field . '=' . $oid;
    }
    if ( $link_info->{url_edit} ) {
        $url_edit  = "$link_info->{url_edit}?" . $id_field . '=' . $oid;
    }
    else {
        $url_edit  = "$link_info->{url}?edit=1;" . $id_field . '=' . $oid;
    }
    return { class     => ref $self,
             object_id => $oid,
             oid       => $oid,
             id_field  => $id_field,
             name      => $object_type,
             title     => $title,
             security  => $self->{tmp_security_level},
             url       => $url,
             url_edit  => $url_edit };
}


# This is very primitive, but objects that want something more
# fancy/complicated can implement it for themselves

sub as_string {
    my ( $self ) = @_;
    my $msg = '';
    my $fields = $self->CONFIG->{as_string_order} || $self->field_list;
    my $labels = $self->CONFIG->{as_string_label} || { map { $_ => $_ } @{ $fields } };
    foreach my $field ( @{ $fields } ) {
        $msg .= sprintf( "%-20s: %s\n", $labels->{ $field }, $self->{ $field } );
    }
    return $msg;
}


# This is even more primitive, but again, we're just providing the
# basics :-)

sub as_html {
    my ( $self ) = @_;
    return "<pre>" . $self->as_string . "\n</pre>\n";
}


########################################
# SECURITY
########################################

# These are the default methods that classes not using security
# inherit. Default action is WRITE, so everything is allowed

sub check_security          { return SEC_LEVEL_WRITE }
sub check_action_security   { return SEC_LEVEL_WRITE }
sub create_initial_security { return 1 }


########################################
# CACHING
########################################

# NOTE: CACHING IS NOT FUNCTIONAL AND THESE MAY RADICALLY CHANGE

# All objects are by default cached; set the key 'no_cache'
# to a true value to *not* cache this object

sub no_cache            { return $_[0]->CONFIG->{no_cache} || 0 }

# Your class should determine how to get to the cache -- the normal
# way is to have all your objects inherit from a common base class
# which deals with caching, datasource handling, etc.

sub global_cache        { return undef }

# Actions to do before/after retrieving/saving/removing
# an item from the cache

sub pre_cache_fetch     { return 1 }
sub post_cache_fetch    { return 1 }
sub pre_cache_save      { return 1 }
sub post_cache_save     { return 1 }
sub pre_cache_remove    { return 1 }
sub post_cache_remove   { return 1 }


sub get_cached_object {
    my ( $class, $p ) = @_;
    return undef unless ( $p->{id} );
    return undef unless ( $class->use_cache( $p ) );

    # If we can retrieve an item from the cache, then create a new object
    # and assign the values from the cache to it.
    my $item_data = $class->global_cache->get({ class     => $class,
                                                object_id => $p->{id} });
    if ( $item_data ) {
        $log->is_info &&
            $log->info( "Retrieving from cache..." );
        return $class->new( $item_data );
    }
    $log->is_info &&
        $log->info( "Cached data not found." );
    return undef;
}


sub set_cached_object {
    my ( $self, $p ) = @_;
    return undef unless ( ref $self );
    return undef unless ( $self->id );
    return undef unless ( $self->use_cache( $p ) );
    return $self->global_cache->set({ data => $self });
}


# Return 1 if we're using the cache; undef if not -- right now we
# always return undef since caching isn't enabled

sub use_cache {
    return undef unless ( $USE_CACHE );
    my ( $class, $p ) = @_;
    return undef if ( $p->{skip_cache} );
    return undef if ( $class->no_cache );
    return undef unless ( $class->global_cache );
    return 1;
}


########################################
# ACCESSORS/MUTATORS
########################################

# We should probably deprecate these...

sub get { return $_[0]->{ $_[1] } }
sub set { return $_[0]->{ $_[1] } = $_[2] }


# return a simple hashref of this object's data -- not tied, not as an
# object

sub as_data_only {
    my ( $self ) = @_;
    my $fields = $self->_get_definitive_fields;
    return { map { $_ => $self->{ $_ } } grep ! /^(tmp|_)/, @{ $fields } };
}

# Backward compatible...

sub data { return as_data_only( @_ ) }

sub AUTOLOAD {
    my ( $item, @params ) = @_;
    my $request = $SPOPS::AUTOLOAD;
    $request =~ s/.*://;

    # First, give a nice warning and return undef if $item is just a
    # class rather than an object

    my $class = ref $item;
    unless ( $class ) {
        $log->warn( "Cannot fill class method '$request' from class '$item'" );
        return undef;
    }

    $log->is_info &&
        $log->info( "AUTOLOAD caught '$request' from '$class'" );

    if ( ref $item and $item->is_checking_fields ) {
        my $fields = $item->field_all_map || {};
        my ( $field_name ) = $request =~ /^(\w+)_clear/;
        if ( exists $fields->{ $request } ) {
            $log->is_debug &&
                $log->debug( "$class to fill param '$request'; returning data." );
            # TODO: make these internal methods inheritable?
            $item->_internal_create_field_methods( $class, $request );
            return $item->$request( @params );
        }
        elsif ( $field_name and exists $fields->{ $field_name } ) {
            $log->is_debug &&
                $log->debug( "$class to fill param clear '$request'; ",
                              "creating '$field_name' methods" );
            $item->_internal_create_field_methods( $class, $field_name );
            return $item->$request( @params );
        }
        elsif ( my $value = $item->{ $request } ) {
            $log->is_debug &&
                $log->debug( " $request must be a temp or something, returning value." );
            return $value;
        }
        elsif ( $request =~ /^tmp_/ ) {
            $log->is_debug &&
                $log->debug( "$request is a temp var, but no value saved. Returning undef." );
            return undef;
        }
        elsif ( $request =~ /^_internal/ ) {
            $log->is_debug &&
                $log->debug( "$request is an internal request, but no value",
                              "saved. Returning undef." );
            return undef;
        }
        $log->warn( "AUTOLOAD Error: Cannot access the method $request via <<$class>>",
               "with the parameters ", join( ' ', @_ ) );
        return undef;
    }
    my ( $field_name ) = $request =~ /^(\w+)_clear/;
    if ( $field_name ) {
        $log->is_debug &&
            $log->debug( "$class is not checking fields, so create sub and return ",
                         "data for '$field_name'" );
        $item->_internal_create_field_methods( $class, $field_name );
    }
    else {
        $log->is_debug &&
            $log->debug( "$class is not checking fields, so create sub and return ",
                         "data for '$request'" );
        $item->_internal_create_field_methods( $class, $request );
    }
    return $item->$request( @params );
}

sub _internal_create_field_methods {
    my ( $item, $class, $field_name ) = @_;

    no strict 'refs';

    # First do the accessor/mutator...
    *{ $class . '::' . $field_name } = sub {
        my ( $self, $value ) = @_;
        if ( defined $value ) {
            $self->{ $field_name } = $value;
        }
        return $self->{ $field_name };
    };

    # Now the mutator to clear the field value
    *{ $class . '::' . $field_name . '_clear' } = sub {
        my ( $self ) = @_;
        delete $self->{ $field_name };
        return undef;
    };

    return;
}


########################################
# DEBUGGING

# DEPRECATED! Use log4perl instead!

sub _w {
    my $lev   = shift || 0;
    if ( $lev == 0 ) {
        $log->warn( @_ );
    }
    elsif ( $lev == 1 ) {
        $log->is_info &&
            $log->info( @_ );
    }
    else {
        $log->is_debug &&
            $log->debug( @_ );
    }
}


sub _wm {
    my ( $lev, $check, @msg ) = @_;
    return _w( $lev, @msg );
}

1;

__END__

=head1 NAME

SPOPS -- Simple Perl Object Persistence with Security

=head1 SYNOPSIS

 # Define an object completely in a configuration file
 
 my $spops = {
   myobject => {
    class   => 'MySPOPS::Object',
    isa     => qw( SPOPS::DBI ),
    ...
   }
 };
 
 # Process the configuration and initialize the class
 
 SPOPS::Initialize->process({ config => $spops });
 
 # create the object
 
 my $object = MySPOPS::Object->new;
 
 # Set some parameters
 
 $object->{ $param1 } = $value1;
 $object->{ $param2 } = $value2;
 
 # Store the object in an inherited persistence mechanism
 
 eval { $object->save };
 if ( $@ ) {
   print "Error trying to save object: $@\n",
         "Stack trace: ", $@->trace->as_string, "\n";
 }

=head1 OVERVIEW

SPOPS -- or Simple Perl Object Persistence with Security -- allows you
to easily define how an object is composed and save, retrieve or
remove it any time thereafter. It is intended for SQL databases (using
the DBI), but you should be able to adapt it to use any storage
mechanism for accomplishing these tasks.  (An early version of this
used GDBM, although it was not pretty.)

The goals of this package are fairly simple:

=over 4

=item *

Make it easy to define the parameters of an object

=item *

Make it easy to do common operations (fetch, save, remove)

=item *

Get rid of as much SQL (or other domain-specific language) as
possible, but...

=item *

... do not impose a huge cumbersome framework on the developer

=item *

Make applications easily portable from one database to another

=item *

Allow people to model objects to existing data without modifying the
data

=item *

Include flexibility to allow extensions

=item *

Let people simply issue SQL statements and work with normal datasets
if they want

=back

So this is a class from which you can derive several useful
methods. You can also abstract yourself from a datasource and easily
create new objects.

The subclass is responsible for serializing the individual objects, or
making them persistent via on-disk storage, usually in some sort of
database. See "Object Oriented Perl" by Conway, Chapter 14 for much
more information.

The individual objects or the classes should not care how the objects
are being stored, they should just know that when they call C<fetch()>
with a unique ID that the object magically appears. Similarly, all the
object should know is that it calls C<save()> on itself and can
reappear at any later date with the proper invocation.

=head1 DESCRIPTION

This module is meant to be overridden by a class that will implement
persistence for the SPOPS objects. This persistence can come by way of
flat text files, LDAP directories, GDBM entries, DBI database tables
-- whatever. The API should remain the same.

Please see L<SPOPS::Manual::Intro|SPOPS::Manual::Intro> and
L<SPOPS::Manual::Object|SPOPS::Manual::Object> for more information
and examples about how the objects work.

=head1 API

The following includes methods within SPOPS and those that need to be
defined by subclasses.

In the discussion below, the following holds:

=over 4

=item *

When we say B<base class>, think B<SPOPS>

=item *

When we say B<subclass>, think of B<SPOPS::DBI> for example

=back

Also see the L<ERROR HANDLING> section below on how we use exceptions
to indicate an error and where to get more detailed infromation.

B<new( [ \%initialize_data ] )>

Implemented by base class.

This method creates a new SPOPS object. If you pass it key/value pairs
the object will initialize itself with the data (see C<initialize()>
for notes on this). You can also implement C<initialize_custom()> to
perform your own custom processing at object initialization (see
below).

Note that you can use the key 'id' to substitute for the actual
parameter name specifying an object ID. For instance:

 my $uid = $user->id;
 if ( eval { $user->remove } ) {
   my $new_user = MyUser->new( { id => $uid, fname = 'BillyBob' ... } );
   ...
 }

In this case, we do not need to know the name of the ID field used by
the MyUser class.

You can also pass in default values to use for the object in the
'default_values' key.

We use a number of parameters from your object configuration. These
are:

=over 4

=item *

B<strict_field> (bool) (optional)

If set to true, you will use the
L<SPOPS::Tie::StrictField|SPOPS::Tie::StrictField> tie implementation,
which ensures you only get/set properties that exist in the field
listing. You can also pass a true value in for C<strict_field> in the
parameters and achieve the same result for this single object

=item *

B<column_group> (\%) (optional)

Hashref of column aliases to arrayrefs of fieldnames. If defined
objects of this class will use L<LAZY LOADING>, and the different
aliases you define can typically be used in a C<fetch()>,
C<fetch_group()> or C<fetch_iterator()> statement. (Whether they can
be used depends on the SPOPS implementation.)

=item *

B<field_map> (\%) (optional)

Hashref of field alias to field name. This allows you to get/set
properties using a different name than how the properties are
stored. For instance, you might need to retrofit SPOPS to an existing
table that contains news stories. Retrofitting is not a problem, but
another wrinkle of your problem is that the news stories need to fit a
certain interface and the property names of the interface do not match
the fieldnames in the existing table.

All you need to do is create a field map, defining the interface
property names as the keys and the database field names as the values.

=item *

B<default_values> (\%) (optional)

Hashref of field names and default values for the fields when the
object is initialized with C<new()>.

Normally the values of the hashref are the defaults to which you want
to set the fields. However, there are two special cases of values:

=over 4

=item B<'NOW'>

This string will insert the current timestamp in the format
C<yyyy-mm-dd hh:mm:ss>.

=item B<\%>

A hashref with the keys 'class' and 'method' will get executed as a
class method and be passed the name of the field for which we want a
default. The method should return the default value for this field.

=back

One problem with setting default values in your object configuration
B<and> in your database is that the two may become unsynchronized,
resulting in many pulled hairs in debugging.

To get around the synchronization issue, you can set this dynamically
using various methods with
L<SPOPS::ClassFactory|SPOPS::ClassFactory>. A simple implementation,
L<SPOPS::Tool::DBI::FindDefaults|SPOPS::Tool::DBI::FindDefaults>, is
shipped with SPOPS.

=back

As the very last step before the object is returned we call
C<initialize_custom( \%initialize_data )>. You can override this
method and perform any processing you wish. The parameters from
C<\%initialize_data> will already be set in the object, and the
'changed' flag will be cleared for all parameters and the 'saved' flag
cleared.

Returns on success: a tied hashref object with any passed data already
assigned. The 'changed' flag is set and the and 'saved' flags is
cleared on the returned object.

Returns on failure: undef.

Examples:

 # Simplest form...
 my $data = MyClass->new();

 # ...with initialization
 my $data = MyClass->new({ balance => 10532,
                           account => '8917-918234' });

B<clone( \%params )>

Returns a new object from the data of the first. You can override the
original data with that in the C<\%params> passed in. You can also clone
an object into a new class by passing the new class name as the
'_class' parameter -- of course, the interface must either be the same
or there must be a 'field_map' to account for the differences.

Note that the ID of the original object will B<not> be copied; you can
set it explicitly by setting 'id' or the name of the ID field in
C<\%params>.

Examples:

 # Create a new user bozo
 
 my $bozo = $user_class->new;
 $bozo->{first_name} = 'Bozo';
 $bozo->{last_name}  = 'the Clown';
 $bozo->{login_name} = 'bozosenior';
 eval { $bozo->save };
 if ( $@ ) { ... report error .... }

 # Clone bozo; first_name is 'Bozo' and last_name is 'the Clown',
 # as in the $bozo object, but login_name is 'bozojunior'
 
 my $bozo_jr = $bozo->clone({ login_name => 'bozojunior' });
 eval { $bozo_jr->save };
 if ( $@ ) { ... report error ... }

 # Copy all users from a DBI datastore into an LDAP datastore by
 # cloning from one and saving the clone to the other
 
 my $dbi_users = DBIUser->fetch_group();
 foreach my $dbi_user ( @{ $dbi_users } ) {
     my $ldap_user = $dbi_user->clone({ _class => 'LDAPUser' });
     $ldap_user->save;
 }

B<initialize( \%initialize_data )>

Implemented by base class; do your own customization using
C<initialize_custom()>.

Cycle through the parameters inn C<\%initialize_data> and set any
fields necessary in the object. This allows you to construct the
object with existing data. Note that the tied hash implementation
optionally ensures (with the 'strict_field' configuration key set to
true) that you cannot set infomration as a parameter unless it is in
the field list for your class. For instance, passing the information:

 firt_name => 'Chris'

should likely not set the data, since 'firt_name' is the misspelled
version of the defined field 'first_name'.

Note that we also set the 'loaded' property of all fields to true, so
if you override this method you need to simply call:

 $self->set_all_loaded();

somewhere in the overridden method.

C<initialize_custom( \%initialize_data )>

Called as the last step of C<new()> so you can perform customization
as necessary. The default does nothing.

Returns: nothing

=head2 Accessors/Mutators

You should use the hash interface to get and set values in your object
-- it is easier. However, SPOPS will also create an
accessor/mutator/clearing-mutator for you on demand -- just call a
method with the same name as one of your properties and two methods
('${fieldname}' and '${fieldname}_clear') will be created. Similar to
other libraries in Perl (e.g., L<Class::Accessor|Class::Accessor>) the
accessor and mutator share a method, with the mutator only being used
if you pass a defined value as the second argument:

 # Accessor
 my $value = $object->fieldname;
 
 # Mutator
 $object->fieldname( 'new value' );
 
 # This won't do what you want (clear the field value)...
 $object->fieldname( undef );
 
 # ... but this will
 $object->fieldname_clear;

The return value of the mutator is the B<new> value of the field which
is the same value you passed in.

Generic accessors (C<get()>) and mutators (C<set()>) are available but
deprecated, probably to be removed before 1.0:

You can modify how the accessors/mutators get generated by overriding
the method:

 sub _internal_create_field_methods {
     my ( $self, $class, $field_name ) = @_;
     ...
 }

This method must create two methods in the class namespace,
'${fieldname}' and '${fieldname}_clear'. Since the value returned from
C<AUTOLOAD> depends on these methods being created, failure to create
them will probably result in an infinite loop.

B<get( $fieldname )>

Returns the currently stored information within the object for C<$fieldname>.

 my $value = $obj->get( 'username' );
 print "Username is $value";

It might be easier to use the hashref interface to the same data,
since you can inline it in a string:

 print "Username is $obj->{username}";

You may also use a shortcut of the parameter name as a method call for
the first instance:

 my $value = $obj->username();
 print "Username is $value";

B<set( $fieldname, $value )>

Sets the value of C<$fieldname> to C<$value>. If value is empty,
C<$fieldname> is set to undef.

 $obj->set( 'username', 'ding-dong' );

Again, you can also use the hashref interface to do the same thing:

 $obj->{username} = 'ding-dong';

You can use the fieldname as a method to modify the field value here
as well:

 $obj->username( 'ding-dong' );

Note that if you want to set the field to C<undef> you will need to
use the hashref interface:

 $obj->{username} = undef;

B<id()>

Returns the ID for this object. Checks in its config variable for the
ID field and looks at the data there.  If nothing is currently stored,
you will get nothing back.

Note that we also create a subroutine in the namespace of the calling
class so that future calls take place more quickly.

=head2 Serialization

B<fetch( $object_id, [ \%params ] )>

Implemented by subclass.

This method should be called from either a class or another object
with a named parameter of 'id'.

Returns on success: an SPOPS object.

Returns on failure: undef; if the action failed (incorrect fieldname
in the object specification, database not online, database user cannot
select, etc.) a L<SPOPS::Exception|SPOPS::Exception> object (or one of
its subclasses) will be thrown to raise an error.

The \%params parameter can contain a number of items -- all are optional.

Parameters:

=over 4

=item *

B<(datasource)> (obj) (optional)

For most SPOPS implementations, you can pass the data source (a DBI
database handle, a GDBM tied hashref, etc.) into the routine. For DBI
this variable is C<db>, for LDAP it is C<ldap>, but for other
implementations it can be something else.

=item *

B<data> (\%) (optional)

You can use fetch() not just to retrieve data, but also to do the
other checks it normally performs (security, caching, rulesets,
etc.). If you already know the data to use, just pass it in using this
hashref. The other checks will be done but not the actual data
retrieval. (See the C<fetch_group> routine in L<SPOPS::DBI|SPOPS::DBI>
for an example.)

=item *

B<skip_security> (bool) (optional)

A true value skips security checks, false or default value keeps them.

=item *

B<skip_cache> (bool) (optional)

A true value skips any use of the cache, always hitting the data
source.

=back

In addition, specific implementations may allow you to pass in other
parameters. (For example, you can pass in 'field_alter' to the
L<SPOPS::DBI|SPOPS::DBI> implementation so you can format the returned data.)

Example:

 my $id = 90192;
 my $data = eval { MyClass->fetch( $id ) };
 
 # Read in a data file and retrieve all objects matching IDs
 
 my @object_list = ();
 while ( <DATA> ) {
   chomp;
   next if ( /\D/ );
   my $obj = eval { ObjectClass->fetch( $_ ) };
   if ( $@ ) { ... report error ... }
   else      { push @object_list, $obj  if ( $obj ) }
 }

B<fetch_determine_limit()>

This method has been moved to L<SPOPS::Utility|SPOPS::Utility>.

B<save( [ \%params ] )>

Implemented by subclass.

This method should save the object state in whatever medium the module
works with. Note that the method may need to distinguish whether the
object has been previously saved or not -- whether to do an add versus
an update. See the section L<TRACKING CHANGES> for how to do this. The
application should not care whether the object is new or pre-owned.

Returns on success: the object itself.

Returns on failure: undef, and a L<SPOPS::Exception|SPOPS::Exception>
object (or one of its subclasses) will be thrown to raise an error.

Example:

 eval { $obj->save };
 if ( $@ ) {
   warn "Save of ", ref $obj, " did not work properly -- $@";
 }

Since the method returns the object, you can also do chained method
calls:

 eval { $obj->save()->separate_object_method() };

Parameters:

=over 4

=item *

B<(datasource)> (obj) (optional)

For most SPOPS implementations, you can pass the data source (a DBI
database handle, a GDBM tied hashref, etc.) into the routine.

=item *

B<is_add> (bool) (optional)

A true value forces this to be treated as a new record.

=item *

B<skip_security> (bool) (optional)

A true value skips the security check.

=item *

B<skip_cache> (bool) (optional)

A true value skips any caching.

=item *

B<skip_log> (bool) (optional)

A true value skips the call to 'log_action'

=back

B<remove()>

Implemented by subclass.

Permanently removes the object, or if called from a class removes the
object having an id matching the named parameter of 'id'.

Returns: status code based on success (undef == failure).

Parameters:

=over 4

=item *

B<(datasource)> (obj) (optional)

For most SPOPS implementations, you can pass the data source (a DBI
database handle, a GDBM tied hashref, etc.) into the routine.

=item *

B<skip_security> (bool) (optional)

A true value skips the security check.

=item *

B<skip_cache> (bool) (optional)

A true value skips any caching.

=item *

B<skip_log> (bool) (optional)

A true value skips the call to 'log_action'

=back

Examples:

 # First fetch then remove

 my $obj = MyClass->fetch( $id );
 my $rv = $obj->remove();

Note that once you successfully call C<remove()> on an object, the
object will still exist as if you had just called C<new()> and set the
properties of the object. For instance:

 my $obj = MyClass->new();
 $obj->{first_name} = 'Mario';
 $obj->{last_name}  = 'Lemieux';
 if ( $obj->save ) {
     my $saved_id = $obj->{player_id};
     $obj->remove;
     print "$obj->{first_name} $obj->{last_name}\n";
 }

Would print:

 Mario Lemieux

But trying to fetch an object with C<$saved_id> would result in an
undefined object, since it is no longer in the datastore.

=head2 Object Information

B<object_description()>

Returns a hashref with metadata about a particular object. The keys of
the hashref are:

=over 4

=item *

B<class> ($)

Class of this object

=item *

B<object_id> ($)

ID of this object. (Also under 'oid' for compatibility.)

=item *

B<id_field> ($)

Field used for the ID.

=item *

B<name> ($)

Name of this general class of object (e.g., 'News')

=item *

B<title> ($)

Title of this particular object (e.g., 'Man bites dog, film at 11')

=item *

B<url> ($)

URL that will display this object. Note that the URL might not
necessarily work due to security reasons.

B<url_edit> ($)

URL that will display this object in editable form. Note that the URL
might not necessarily work due to security reasons.

=back

You control what's used in the 'display' class configuration
variable. In it you can have the keys 'url', which should be the basis
for a URL to display the object and optionally 'url_edit', the basis
for a URL to display the object in editable form. A query string with
'id_field=ID' will be appended to both, and if 'url_edit' is not
specified we create it by adding a 'edit=1' to the 'url' query
string.

So with:

 display => {
   url      => '/Foo/display/',
   url_edit => '/Foo/display_form',
 }

The defaults put together by SPOPS by reading your configuration file
might not be sufficiently dynamic for your object. In that case, just
override the method and substitute your own. For instance, the
following adds some sort of sales adjective to the beginning of every
object title:

  package My::Object;
 
  sub object_description {
      my ( $self ) = @_;
      my $info = $self->SUPER::object_description();
      $info->{title} = join( ' ', sales_adjective_of_the_day(),
                                  $info->{title} );
      return $info;
  }

And be sure to include this class in your 'code_class' configuration
key. (See L<SPOPS::ClassFactory|SPOPS::ClassFactory> and
L<SPOPS::Manual::CodeGeneration|SPOPS::Manual::CodeGeneration> for
more info.)

B<as_string>

Represents the SPOPS object as a string fit for human consumption. The
SPOPS method is extremely crude -- if you want things to look nicer,
override it.

B<as_html>

Represents the SPOPS object as a string fit for HTML (browser)
consumption. The SPOPS method is double extremely crude, since it just
wraps the results of C<as_string()> (which itself is crude) in
'E<lt>preE<gt>' tags.

=head2 Lazy Loading

B<is_loaded( $fieldname )>

Returns true if C<$fieldname> has been loaded from the datastore,
false if not.

B<set_loaded( $fieldname )>

Flags C<$fieldname> as being loaded.

B<set_all_loaded()>

Flags all fieldnames (as returned by C<field_list()>) as being loaded.

=head2 Field Checking

B<is_checking_fields()>

Returns true if this class is doing field checking (setting
'strict_field' equal to a true value in the configuration), false if
not.

=head2 Modification State

B<is_changed()>

Returns true if this object has been changed since being fetched or
created, false if not.

B<has_change()>

Set the flag telling this object it has been changed.

B<clear_change()>

Clear the change flag in an object, telling it that it is unmodified.

=head2 Serialization State

B<is_saved()>

Return true if this object has ever been saved, false if not.

B<has_save()>

Set the saved flag in the object to true.

B<clear_save()>

Clear out the saved flag in the object.

=head2 Configuration

Most of this information can be accessed through the C<CONFIG>
hashref, but we also need to create some hooks for subclasses to
override if they wish. For instance, language-specific objects may
need to be able to modify information based on the language
abbreviation.

We have simple methods here just returning the basic CONFIG
information.

B<no_cache()> (bool)

Returns a boolean based on whether this object can be cached or
not. This does not mean that it B<will> be cached, just whether the
class allows its objects to be cached.

B<field()> (\%)

Returns a hashref (which you can sort by the values if you wish) of
fieldnames used by this class.

B<field_list()> (\@)

Returns an arrayref of fieldnames used by this class.

Subclasses can define their own where appropriate.

=head2 "Global" Configuration

These objects are tied together by just a few things:

B<global_cache>

A caching object. Caching in SPOPS is not tested but should work --
see L<Caching> below.

=head2 Caching

Caching in SPOPS is not tested but should work. If you would like to
brave the rapids, then call at the beginning of your application:

 SPOPS->set_global_use_cache(1);

You will also need to make a caching object accessible to all of your
SPOPS classes via a method C<global_cache()>. Each class can turn off
caching by setting a true value for the configuration variable
C<no_cache> or by passing in a true value for the parameter
'skip_cache' as passed to C<fetch>, C<save>, etc.

The object returned by C<global_cache()> should return an object which
implements the methods C<get()>, C<set()>, C<clear()>, and C<purge()>.

The method C<get()> should return the property values for a particular
object given a class and object ID:

 $cache->get({ class => 'SPOPS-class', object_id => 'id' })

The method B<set()> should saves the property values for an object
into the cache:

 $cache->set({ data => $spops_object });

The method B<clear()> should clear from the cache the data for an
object:

 $cache->clear({ data => $spops_object });
 $cache->clear({ class => 'SPOPS-class', object_id => 'id' });

The method B<purge()> should remove B<all> items from the cache.

This is a fairly simple interface which leaves implementation pretty
much wide open.

=head2 Timestamp Methods

These have gone away (you were warned!)

=head2 Debugging

The previous (fragile, awkward) debugging system in SPOPS has been
replaced with L<Log::Log4perl> instead. Old calls to C<DEBUG>, C<_w>,
and C<_wm> will still work (for now) but they just use log4perl under
the covers.

Please see L<SPOPS::Manual::Configuration> under L<LOGGING> for
information on how to configure it.

=head1 NOTES

There is an issue using these modules with
L<Apache::StatINC|Apache::StatINC> along with the startup methodology
that calls the C<class_initialize> method of each class when a httpd
child is first initialized. If you modify a module without stopping
the webserver, the configuration variable in the class will not be
initialized and you will inevitably get errors.

We might be able to get around this by having most of the
configuration information as static class lexicals. But anything that
depends on any information from the CONFIG variable in request (which
is generally passed into the C<class_initialize> call for each SPOPS
implementation) will get hosed.

=head1 TO DO

B<Method object_description() should be more robust>

In particular, the 'url' and 'url_edit' keys of object_description()
should be more robust.

B<Objects composed of many records>

An idea: Make this data item framework much like the one
Brian Jepson discusses in Web Techniques:

 http://www.webtechniques.com/archives/2000/03/jepson/

At least in terms of making each object unique (having an OID).
Each object could then be simply a collection of table name
plus ID name in the object table:

 CREATE TABLE objects (
   oid        int not null,
   table_name varchar(30) not null,
   id         int not null,
   primary key( oid, table_name, id )
 )

Then when you did:

 my $oid  = 56712;
 my $user = User->fetch( $oid );

It would first get the object composition information:

 oid    table        id
 ===    =====        ==
 56712  user         1625
 56712  user_prefs   8172
 56712  user_history 9102

And create the User object with information from all
three tables.

Something to think about, anyway.

=head1 BUGS

None known.

=head1 COPYRIGHT

Copyright (c) 2001-2004 intes.net, inc; (c) 2003-2004-2004-2004 Chris
Winters. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

Find out more about SPOPS -- current versions, updates, rants, ideas
-- at:

 http://spops.sourceforge.net/

CVS access and mailing lists (SPOPS is currently supported by the
openinteract-dev list) are at:

 http://sourceforge.net/projects/spops/

Also see the 'Changes' file in the source distribution for comments
about how the module has evolved.

L<SPOPSx::Ginsu> - Generalized Inheritance Support for SPOPS + MySQL
-- store inherited data in separate tables.

=head1 AUTHORS

Chris Winters E<lt>chris@cwinters.comE<gt>

The following people have offered patches, advice, development funds,
etc. to SPOPS:

=over 4

=item *

Ray Zimmerman E<lt>rz10@cornell.eduE<gt> -- has offered tons of great design
ideas and general help, pushing SPOPS into new domains. Too much to
list here.

=item *

Simon Ilyushchenko E<lt>simonf@cshl.eduE<gt> -- real-world usage
advice, work on improving the object linking semantics, lots of little
items.

=item *

Christian Lemburg E<lt>lemburg@aixonix.deE<gt> -- contributed excellent
documentation, too many good ideas to implement as well as design help
with L<SPOPS::Secure::Hierarchy|SPOPS::Secure::Hierarchy>, the
rationale for moving methods from the main SPOPS subclass to
L<SPOPS::Utility|SPOPS::Utility>

=item *

Raj Chandran E<lt>rc264@cornell.eduE<gt> submitted a patch to make
some L<SPOPS::SQLInterface|SPOPS::SQLInterface> methods work as
advertised.

=item *

Rusty Foster E<lt>rusty@kuro5hin.orgE<gt> -- was influential (and not
always in good ways) in the early days of this library and offered up
an implementation for 'limit' functionality in
L<SPOPS::DBI|SPOPS::DBI>

=item *

Rick Myers E<lt>rik@sumthin.nuE<gt> -- got rid of lots of warnings when
running under C<-w> and helped out with permission issues with
SPOPS::GDBM.

=item *

Harry Danilevsky E<lt>hdanilevsky@DeerfieldCapital.comE<gt> -- helped out with
Sybase-specific issues, including inspiring
L<SPOPS::Key::DBI::Identity|SPOPS::Key::DBI::Identity>.

=item *

Leon Brocard E<lt>acme@astray.comE<gt> -- prodded better docs of
L<SPOPS::Configure|SPOPS::Configure>, specifically the linking
semantics.

=item *

David Boone E<lt>dave@bis.bc.caE<gt> -- prodded the creation of
L<SPOPS::Initialize|SPOPS::Initialize>.

=item *

MSN Marketing Service Nordwest, GmbH -- funded development of LDAP
functionality, including L<SPOPS::LDAP|SPOPS::LDAP>,
L<SPOPS::LDAP::MultiDatasource|SPOPS::LDAP::MultiDatasource>, and
L<SPOPS::Iterator::LDAP|SPOPS::Iterator::LDAP>.

=back
