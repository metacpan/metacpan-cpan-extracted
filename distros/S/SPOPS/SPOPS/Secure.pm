package SPOPS::Secure;

# $Id: Secure.pm,v 3.14 2004/06/02 00:48:21 lachoy Exp $

use strict;
use base  qw( Exporter );
use vars  qw( $EMPTY );
use Data::Dumper  qw( Dumper );
use Log::Log4perl qw( get_logger );

$SPOPS::Secure::VERSION  = sprintf("%d.%02d", q$Revision: 3.14 $ =~ /(\d+)\.(\d+)/);

# Stuff for security constants and exporting

use constant SEC_LEVEL_NONE          => 1;
use constant SEC_LEVEL_SUMMARY       => 2;
use constant SEC_LEVEL_READ          => 4;
use constant SEC_LEVEL_WRITE         => 8;

use constant SEC_LEVEL_NONE_VERBOSE    => 'NONE';
use constant SEC_LEVEL_SUMMARY_VERBOSE => 'SUMMARY';
use constant SEC_LEVEL_READ_VERBOSE    => 'READ';
use constant SEC_LEVEL_WRITE_VERBOSE   => 'WRITE';

use constant SEC_SCOPE_USER          => 'u';
use constant SEC_SCOPE_GROUP         => 'g';
use constant SEC_SCOPE_WORLD         => 'w';

my $log = get_logger();

my @LEVEL = qw( SEC_LEVEL_NONE SEC_LEVEL_SUMMARY SEC_LEVEL_READ SEC_LEVEL_WRITE );
my @SCOPE = qw( SEC_SCOPE_USER SEC_SCOPE_GROUP SEC_SCOPE_WORLD );
my @VRBS  = qw( SEC_LEVEL_NONE_VERBOSE SEC_LEVEL_SUMMARY_VERBOSE
                SEC_LEVEL_READ_VERBOSE SEC_LEVEL_WRITE_VERBOSE );

@SPOPS::Secure::EXPORT_OK = ( '$EMPTY', @LEVEL, @SCOPE, @VRBS );
%SPOPS::Secure::EXPORT_TAGS = (
    all     => [ @LEVEL, @SCOPE, @VRBS ],
    scope   => [ @SCOPE ],
    level   => [ @LEVEL ],
    verbose => [ @VRBS ],
);

# Dummy (empty) hashref to pass back if we need to
# basically deny the request -- e.g., they asked for a
# user that isn't an object, they asked for the current
# user and there is none, etc.

$EMPTY = {
    SEC_SCOPE_WORLD() => SEC_LEVEL_NONE,
    SEC_SCOPE_USER()  => SEC_LEVEL_NONE,
    SEC_SCOPE_GROUP() => {}
};

my %LEVEL_VERBOSE = (
    SEC_LEVEL_NONE_VERBOSE()     => SEC_LEVEL_NONE,
    SEC_LEVEL_SUMMARY_VERBOSE()  => SEC_LEVEL_SUMMARY,
    SEC_LEVEL_READ_VERBOSE()     => SEC_LEVEL_READ,
    SEC_LEVEL_WRITE_VERBOSE()    => SEC_LEVEL_WRITE,
);

my %LEVEL_CODE = map { $LEVEL_VERBOSE{ $_ } => $_ } keys %LEVEL_VERBOSE;

my $INITIAL_SECURITY_DEFAULT = SEC_LEVEL_NONE;

# This needs to be down here so we don't get into a deadlock (and die)
# situation

require SPOPS::Exception::Security;
require SPOPS::Secure::Util;

########################################
# RETRIEVE SECURITY
########################################

# Typical calls:
#  $self->check_action_security({ required => SEC_LEVEL_WRITE });
#  $class->check_action_security({ required => SEC_LEVEL_READ, id => $id });

# Note that we return SEC_LEVEL_WRITE to all requests where the object
# does not have an ID -- meaning that the object has not yet been
# saved, and this object creation security must be handled by the
# application rather than SPOPS

# Returns the security level if ok, die()s with an error message if not

# TODO: What is the difference between check_security and
# check_action_security? Do we need both? Should we only expose
# check_action_security()?

sub check_action_security {
    my ( $item, $p ) = @_;
    $log->is_debug &&
        $log->debug( "Trying to check security on: ",
                      ( ref $item ) ? ref( $item ) . " " . $item->id : $item,
                      " with params: ", Dumper( $p ) );

    # since the assumption outlined above (only saved objects have ids)
    # might not be true in all cases, provide an escape route for classes
    # that need security and want to handle their ids themselves

    return SEC_LEVEL_WRITE if ( $p->{is_add} ); # or ! $item->is_saved );

    # If the class has told us they're not using security (even tho
    # SPOPS::Secure is in the 'isa', then everyone can do everything

    return SEC_LEVEL_WRITE if ( $item->no_security );

    # This gets filled with the found security level, oddly, the user
    # can pass in a security level if it's already been found

    my $level = $p->{security_level};

    my ( $class, $id );

    # If not already defined, find the security level explicitly

    unless ( $level ) {

        # Check to see that the ID exists -- if not, it's an add and will
        # not be checked since SPOPS relies on your application to implement
        # who should and should not create an object.

        $class = ref $item || $item;
        $id    = ( ref $item ) ? $item->id : $p->{id};
        unless ( $id ) {
            $log->is_info &&
                $log->info( "ID not found, returning WRITE security" );
            return SEC_LEVEL_WRITE;
        }
        $log->is_debug &&
            $log->debug( "Checking action on $class [$id] and required ",
                          "level is [$p->{required}]" );

        # Calls to SPOPS::Secure->... note that we do not need to
        # explicitly pass in group/user information, since SPOPS::Secure
        # will retrieve it for us.

        # TODO: Revisit that we allow exceptions to bubble up

        $level = $class->check_security({ class     => $class,
                                          object_id => $id,
                                          object    => ( ref $item ) ? $item : undef });

    }
    $log->is_info &&
        $log->info( "Found security level of ($level)" );

    # If the level is below what is necessary call
    # register_security_error() which should set an error message and
    # die with a general one.

    if ( $level < $p->{required} ) {
        $class->register_security_error({ class => $class, id => $id,
                                          level => $level,
                                          required => $p->{required} });
    }
    return $level; # Rock and roll
}


sub register_security_error {
    my ( $class, $p ) = @_;
    $log->is_info &&
        $log->info( "Cannot access $p->{class} record with ID $p->{id}; ",
                      "access: $p->{level} while $p->{required} is required." );
    SPOPS::Exception::Security->throw( "Access denied due to security level",
                                       { required => $p->{required},
                                         found    => $p->{level} } );
}


# Returns: security level for a particular object/class given a scope
# and if necessary, a scope_id; should always return at least the
# security level for the WORLD scope, since everything must have at
# least a permission for the WORLD scope.

sub check_security {
    my ( $class, $p ) = @_;
    my $sec_info = $p->{sec_info};
    unless ( $sec_info ) {
        $log->is_info &&
            $log->info( "Retrieving security information using get_security()" );
        $p->{user} = shift @{ $p->{user} }   if ( ref $p->{user} eq 'ARRAY' );

        # Retrieve security. If a subclass wants to implement a different
        # way of implementing security, this is the method to override.

        # TODO: Revisit exception bubble up from here

        $sec_info = $class->get_security( $p );
    }

    $log->is_info &&
        $log->info( "Security information:\n", Dumper( $sec_info ) );

    # If a user security level exists, return it

    if ( my $user_level = $sec_info->{ SEC_SCOPE_USER() } ) {
        $log->is_info &&
            $log->info( "Return level [$user_level] at scope USER." );
        return $user_level;
    }

    # Go through the groups; if there are groups, we return the highest
    # level among them.

    my $group_max = 0;
    $sec_info->{ SEC_SCOPE_GROUP() } ||= {};
    foreach my $gid ( keys %{ $sec_info->{ SEC_SCOPE_GROUP() } } ) {
        my $group_level = $sec_info->{ SEC_SCOPE_GROUP() }{ $gid };
        next unless ( $group_level );
        $group_max = ( $group_level > $group_max ) ? $group_level : $group_max;
        $log->is_info &&
            $log->info( "Level of GROUP [$gid] is [$group_level]" );
    }
    return $group_max  if ( $group_max );

    my $world_level = $sec_info->{ SEC_SCOPE_WORLD() };
    $log->is_info &&
        $log->info( "Return level [$world_level] at scope WORLD" );
    return $world_level;
}


# Returns hashref

sub get_security {
    my ( $item, $p ) = @_;

    # Since we can pass in the class/oid, those take precedence

    my ( $class, $oid ) = SPOPS::Secure::Util->find_class_and_oid( $item, $p );
    $log->is_info &&
        $log->info( "Checking security for [$class] [$oid] with:\n", Dumper( $p ) );
    my ( $user, $group_list ) = $item->get_security_scopes( $p );

    if ( my $security_info = $item->_check_superuser( $user, $group_list ) ) {
        $log->is_info &&
            $log->info( "Superuser is logged in, can do anything" );
        return $security_info;
    }

    my $sec_obj_class = $p->{security_object_class} ||
                        $item->global_security_object_class;
    $log->is_info &&
        $log->info( "Using security object [$sec_obj_class]" );

    # TODO: Revisit exception bubble up from here

    my $sec_listing = $sec_obj_class->fetch_by_object( $class,
                                                       { object_id => $oid,
                                                         user      => $user,
                                                         group     => $group_list } );
    return $sec_listing || \%{ $EMPTY };
}



sub get_security_scopes {
    my ( $item, $p ) = @_;
    my $user       = undef;
    my $group_list = [];

    $log->is_info &&
        $log->info( "Checking security scopes with:\n", Dumper( $p ) );

    # If both user and group(s) are passed in, we need to modify the
    # group list to include the groups that the user belongs to as well
    # as the groups specified

    if ( $p->{user} and $p->{group} ) {
        $log->is_info &&
            $log->info( "Both user and group were specified." );
        $user       = $p->{user};
        $group_list = eval { $user->group };
        $log->warn( "Cannot fetch groups from user record: $@." ) if ( $@ );
        push @{ $group_list }, ( ref $p->{group} eq 'ARRAY' )
                                 ? @{ $p->{group} } : ( $p->{group} );
    }

    # The default (no user, no group) is just to get the user and its
    # groups

    elsif ( ! $p->{user} and ! $p->{group} ) {
        $log->is_info &&
            $log->info( "Neither user/group specified, using logins." );
        $user       = $item->global_user_current;
        $group_list = $item->global_group_current || [];

        # If no user or group was passed in, and we cannot retrieve a
        # user object with the global_user_current() or group objects
        # with global_group_current(), then all we want to get is the
        # WORLD security level, which means we can skip the
        # user/group_list stuff altogether

        # NOTE: even tho it doesn't appear, there IS a dependency between
        # the next two clauses; that is, you *MUST NOT* check to see if
        # $user->{user_id} == 1 if there actually is no user. Otherwise
        # perl will autovivify a hashref in $R->{auth}{user} which
        # will throw a 800-pound monkey wrench into operations.
        # We really need to look into that, it's quite brittle.

        unless ( $user or scalar @{ $group_list } > 0 ) {
            $log->is_info &&
                $log->info( "No user or groups found." );
            $user       = undef;
            $group_list = undef;
        }
    }

    # If we were given a user to check, base the group_list around the
    # groups the user belongs to

    elsif ( $p->{user} ) {
        $log->is_info &&
            $log->info( "Only user specified; using user's groups." );
        $user       = $p->{user};
        $group_list = eval { $user->group; };
        $log->warn( "Cannot fetch groups from user record: $@." ) if ( $@ );
    }

    # Otherwise, the group list is based on whatever was passed in

    elsif ( $p->{group} ) {
        $log->is_info &&
            $log->info( "Only group specified." );
        $group_list = ( ref $p->{group} eq 'ARRAY' )
                        ? $p->{group}: [ $p->{group} ];
    }
    return ( $user, $group_list );
}


########################################
# SET SECURITY
########################################


sub create_initial_security {
    my ( $item, $p ) = @_;

    # Since we can pass in the class/oid, those take precedence

    my ( $class, $oid ) = SPOPS::Secure::Util->find_class_and_oid( $item, $p );
    $log->is_info &&
        $log->info( "Setting initial security for $class ($oid)" );

    # \%init describes the initial security to create for this object;
    # note that \%init may describe code to execute or it may simply
    # describe a level to denote

    my $init = $class->creation_security;
    return undef unless ( ref $init and scalar keys %{ $init } );

    # Get the current user and groups

    my $user  = $class->global_user_current;
    my $group = $class->global_group_current;

    # \%level holds the actual security settings for this object

    my $level = {};

    # If our level assignment looks like this:
    # creation_security => {
    #  code => [ 'MyApp::SecurityPolicy' => 'handler' ] },
    # },
    #
    # Then we execute "MyApp::SecurityPolicy->handler( \% ), passing the
    # parameters class and oid (for the object), $user (current user
    # object) and $group (arrayref of groups the user belongs to)
    #

    # The code should return a hashref of either scope => SEC_LEVEL_* (in
    # the case of USER and WORLD) or scope => { scope_id => SEC_LEVEL* }
    # (in the case of GROUP). If an 'undef' is passed for a scope then
    # that scope will not be processed. For example:
    #
    # return { u => undef,
    #          g => { $main_gid => SEC_LEVEL_READ, $admin_gid => SEC_LEVEL_WRITE },
    #          w => SEC_LEVEL_NONE };

    if ( ref $init->{code} eq 'ARRAY' ) {
        my ( $pkg, $method ) = @{ $init->{code} };
        $log->is_info &&
            $log->info( "$pkg\-\>$method being executed for security" );
        $level = $pkg->$method({ class     => $class,
                                 object_id => $oid,
                                 user      => $user,
                                 group     => $group });
        $log->is_info &&
            $log->info( "Result of code:\n", Dumper( $level ) );
    }

    # Go through each scope specified in the init and evaluate the
    # specification for initial security.

    else {

        # Create a list of the group_id for ez-reference

        my @gid = map { $_->{group_id} } @{ $group };

SCOPE:
        foreach my $scope ( keys %{ $init } ) {
            my $todo = $init->{ $scope };
            next unless ( $todo );
            $log->is_info &&
                $log->info( "Determining security level for $scope" );

            # If our level assignment looks like this:
            # creation_security => {
            #  ...,
            #  g => { 3 => WRITE },
            #  ...,
            # },
            #
            # Then we want to do the assignments for the IDs in that scope

            if ( ref $todo eq 'HASH' ) {
                $level->{ $scope } = { map { $_ => $LEVEL_VERBOSE{ uc $todo->{$_} } }
                                           keys %{ $todo } };
            }

            # Otherwise it will look like this:
            # creation_security => {
            #  ...,
            #  g => 'WRITE',
            #  ...,
            # },
            #
            # Which means we'd want to apply WRITE for all the groups
            # to which this user belongs. Be careful with this!
            # (remember that 'public' is a group, too).

            else {
                if ( $scope eq 'w' ) {
                    $level->{w} = $LEVEL_VERBOSE{ uc $todo };
                }
                elsif ( $scope eq 'u' and ref $user ) {
                    $level->{u} = { $user->id() => $LEVEL_VERBOSE{ uc $todo } };
                }
                elsif ( $scope eq 'g' ) {
                    $level->{g} = { map { $_ => $LEVEL_VERBOSE{ uc $todo } } @gid };
                }
            }
        }
        $log->is_info &&
            $log->info( "Level assigned:\n", Dumper( $level ) );
    }

    # Now that \%level is all setup, process it

    # Ensure that this is a *$class* (this was the focus of bugs earlier,
    # exhibited by something in the sys_security table that looks like
    # "This::Class=HASH(0x8bb7028)"

    my $obj_class = ref $class || $class;

    # First do WORLD

    $level->{w} ||= $INITIAL_SECURITY_DEFAULT;
    $class->set_item_security({
                   class          => $obj_class,
                   object_id      => $oid,
                   security_level => $level->{w},
                   scope          => SEC_SCOPE_WORLD });
    $log->is_info &&
        $log->info( "Set initial security for WORLD to $level" );

    # Doing the user and group perms is identical, so we don't
    # need to partition by scope for them

    # Note that we're relying on the fact that u => SEC_SCOPE_USER and
    # g  => SEC_SCOPE_GROUP; if this changes we'll have to do a little
    # mapping from the scopes in $level to the actual scope values

    # TODO: Should collect exceptions as we go?

    foreach my $scope ( ( SEC_SCOPE_USER, SEC_SCOPE_GROUP ) ) {
        next unless ( ref $level->{ $scope } eq 'HASH' );
        foreach my $id ( keys %{ $level->{ $scope } } ) {
            $id ||= '';
            $class->set_item_security({
                       class          => $obj_class,
                       object_id      => $oid,
                       security_level => $level->{ $scope }{ $id },
                       scope          => $scope,
                       scope_id       => $id });
            $log->is_info &&
                $log->info( "Set initial security for $scope ($id) to $level->{$scope}{$id}" );
        }
    }
    return 1;
}


# Set security for one or more objects

sub set_security {
    my ( $item, $p ) = @_;
    my $sec_obj_class = $p->{security_object_class} ||
                        $item->global_security_object_class;

    my $level = $p->{level} || $p->{security_level};

    # First ensure that both a level is specified...

    unless ( $level ) {
        SPOPS::Exception->throw( 'Cannot set security: no permissions defined' );
    }

    # ...and that a scope is specified

    unless ( $p->{scope} ) {
        SPOPS::Exception->throw( 'Cannot set security: no scope defined' );
    }

    # Since we can pass in the class/oid, those take precedence

    my ( $class, $oid ) = SPOPS::Secure::Util->find_class_and_oid( $item, $p );
    $log->is_info &&
        $log->info( "Checking security for $class [$oid]" );

    # If we were passed a particular scope, just return
    # the results of updating that information

    unless ( ref $p->{scope} ) {
        if ( $p->{scope} eq SEC_SCOPE_WORLD ) {
            return $item->set_item_security({
                               class          => $class,
                               object_id      => $oid,
                               security_level => $level,
                               scope          => $p->{scope},
                               scope_id       => $p->{scope_id} } );
        }

        # For user/group, we can pass in multiple items for which we
        # want to set security acting upon a particular class/object;
        # the test for this is if $level is a hashref.

        elsif ( $p->{scope} eq SEC_SCOPE_GROUP or $p->{scope} eq SEC_SCOPE_USER ) {
            if ( ref $level eq 'HASH' ) {
                return $item->set_multiple_security({
                                 class          => $class,
                                 object_id      => $oid,
                                 security_level => $level,
                                 scope          => $p->{scope} } );
            }
            return $item->set_item_security({
                               class          => $class,
                               object_id      => $oid,
                               security_level => $level,
                               scope          => $p->{scope},
                               scope_id       => $p->{scope_id} } );
        }
        SPOPS::Exception->throw( "Set security failed: unrecognized scope " .
                                 "[$p->{scope}] defined" );
    }

    # If we've made it here, the scope should be a reference. But if
    # it's not an arrayref, we have a problem

    if ( ref $p->{scope} ne 'ARRAY' ) {
        SPOPS::Exception->throw( "Set security failed: unrecognized scope " .
                                 "[$p->{scope}] defined" );
    }

    # If level is not a hashref (since we are using multiple scopes)
    # at this point, we have a problem

    if ( ref $level ne 'HASH' ) {
        SPOPS::Exception->throw( "Set security failed: there are multiple scopes" .
                                 "but security_level does not match " );
    }

    # If we were passed multiple scope entries, go through each one
    # and total up the items changed for return. Note that we no
    # longer have a need for scope_id (for user/group) since that logic
    # is embedded within the level hashref

    # Note that *removing* security must be done outside this routine.
    # That is, you can't simply pass a full list of 'new' security
    # options for a particular object/class and expect this method to
    # sort them out for you

    my $count = 0;

SCOPE:
    foreach my $scope ( @{ $p->{scope} } ) {
        if ( $scope eq SEC_SCOPE_WORLD ) {
            $count += $item->set_item_security({
                                  class          => $class,
                                  object_id      => $oid,
                                  scope          => $scope,
                                  security_level => $level->{ $scope } });
        }
        elsif ( $scope eq SEC_SCOPE_GROUP or $scope eq SEC_SCOPE_USER ) {
            $count += $item->set_multiple_security({
                                  class          => $class,
                                  object_id      => $oid,
                                  scope          => $scope,
                                  security_level => $level->{ $scope } });
        }
        else {
            $log->warn( "Cannot set security for scope [$scope] since it is not ",
                    join( '/', SEC_SCOPE_WORLD, SEC_SCOPE_USER, SEC_SCOPE_GROUP ) );
        }
    }
    return $count;
}


sub set_item_security {
    my ( $item, $p ) = @_;

    my $level = $p->{level} || $p->{security_level};

    # Since we can pass in the class/oid, those take precedence

    my ( $class, $oid ) = SPOPS::Secure::Util->find_class_and_oid( $item, $p );

    $p->{scope_id} ||= '';
    $log->is_info &&
        $log->info( "Modifying scope $p->{scope} ($p->{scope_id}) for ",
                    "$class ($oid) with $level" );

    my $sec_obj_class = $p->{security_object_class} ||
                        $item->global_security_object_class;
    my $obj = $sec_obj_class->fetch_match( $class,
                                           { object_id => $oid,
                                             scope     => $p->{scope},
                                             scope_id  => $p->{scope_id} } );
    return 1 if ( $obj and $obj->{security_level} == $level );

    unless ( $obj ) {
        $log->is_info &&
            $log->info( "Current object does not exist. Creating one [$oid]" );
        $obj = $sec_obj_class->new({ class     => $class,
                                     object_id => $oid,
                                     scope     => $p->{scope},
                                     scope_id  => $p->{scope_id} });
    }


    # Otherwise set the level and save, letting any errors from the
    # save bubble up

    $obj->{security_level} = $level;
    return $obj->save;
}


sub set_multiple_security {
    my ( $item, $p ) = @_;

    # Since we can pass in the class/oid, those take precedence

    my ( $class, $oid ) = SPOPS::Secure::Util->find_class_and_oid( $item, $p );
    $log->is_info &&
        $log->info( "Setting multiple security for $class ($oid) and ",
                      "scope $p->{scope}." );

    my $sec_obj_class = $p->{security_object_class} ||
                        $item->global_security_object_class;

    my $level = $p->{level} || $p->{security_level};

    $item->_remove_superuser_level( $level );

    # Count up the number of modifications we are making -- if there
    # are none then we're done

    return 1 unless ( scalar keys %{ $level } );
    my $count = 0;

ITEM:
    foreach my $id ( keys %{ $level } ) {
        $log->is_info &&
            $log->info( "Setting ID $id to $level->{$id}" );
        $count += $item->set_item_security({ class          => $class,
                                             object_id      => $oid,
                                             scope          => $p->{scope},
                                             scope_id       => $id,
                                             security_level => $level->{ $id } });
    }
    return $count;
}


sub remove_item_security {
    my ( $item, $p ) = @_;
    if ( $p->{scope} ne SEC_SCOPE_WORLD and $p->{scope_id} == 1 ) {
        $log->warn( "Will not remove security with scope $p->{scope} ($p->{scope_id}) - admin." );
        return undef;
    }

    # Since we can pass in the class/oid, those take precedence

    my ( $class, $oid ) = SPOPS::Secure::Util->find_class_and_oid( $item, $p );
    $log->is_info &&
        $log->info( "Removing security for $class ($oid) with ",
                      "scope $p->{scope} ($p->{scope_id})" );

    my $sec_obj_class = $p->{security_object_class} ||
                        $item->global_security_object_class;
    my $obj = eval { $sec_obj_class->fetch_match(
                                     $class,
                                     { object_id => $oid,
                                       scope     => $p->{scope},
                                       scope_id  => $p->{scope_id} }) };
    if ( $@ ) {
        $log->warn( "Error found trying to match parameters to an existing object\n",
               "Error: $@->{error}\nSQL: $@->{sql}" );
    }
    unless ( $obj ) {
        $log->warn( "Security object does not exist with parameters, so we cannot remove it." );
        return undef;
    }

    # Let error trickle up

    return $obj->remove;
}


########################################
# SCOPE RETRIEVAL METHODS
########################################

# If no users/groups are available, these ensure we just check WORLD

sub global_user_current  {
    $log->is_info &&
        $log->info( "Using empty definition for current user; this may not be what you want" );
    return undef
}


sub global_group_current {
    $log->is_info &&
        $log->info( "Using empty definition for current groups; this may not be what you want" );
    return [];
}


########################################
# ROOT CHECKS
########################################

sub get_superuser_id  { return 1 }
sub get_supergroup_id { return 1 }

# Define comparison operations for superuser/supergroup

sub is_superuser {
    my ( $class, $id ) = @_;
    return ( $id eq $class->get_superuser_id );
}

sub is_supergroup {
    my ( $class, @id ) = @_;
    my $super_gid = $class->get_supergroup_id;
    return grep { $_ eq $super_gid } @id;
}


# See if this is the superuser or a member of the supergroup

sub _check_superuser {
    my ( $item, $user,  $group_list ) = @_;
    return undef unless ( $user or $group_list );
    my %allow_all = %{ $EMPTY };
    $allow_all{ SEC_SCOPE_USER() } = SEC_LEVEL_WRITE;

    if ( ref $user and $item->is_superuser( $user->{user_id} ) ) {
        $log->is_info &&
            $log->info( "User is superuser, checking ($item)" );
        return \%allow_all;
    }
    if ( ref $group_list eq 'ARRAY' ) {
        if ( $item->is_supergroup( map { $_->{group_id} } @{ $group_list } ) ) {
            return \%allow_all ;
        }
    }
    return undef;
}


# Removes the superuser and supergroup levels from \%level

sub _remove_superuser_level {
    my ( $class, $level ) = @_;
    return unless ( ref $level eq 'HASH' and scalar keys %{ $level } );
    my $super_gid = $class->get_supergroup_id;
    delete $level->{ $class->get_superuser_id };
    delete $level->{ $class->get_supergroup_id };
}


1;

__END__

=head1 NAME

SPOPS::Secure - Implement security across one or more classes of SPOPS objects

=head1 SYNOPSIS

 # In the configuration for your object, add security to objects
 # created by this class:

 $spops = {
   myobject => {
        class => 'My::Object',
        isa   => [ qw/ SPOPS::Secure SPOPS::DBI / ],
   },
 };

=head1 DESCRIPTION

By adding this module into the 'isa' configuration key for your SPOPS
class, you implement a mostly transparent per-object security
system. This security system relies on a few things being implemented:

=over 4

=item *

A SPOPS class implementing users

=item *

A SPOPS class implementing groups

=item *

A SPOPS class implementing security objects

=back

Easy, eh? Fortunately, SPOPS comes with all three, although you are
free to modify them as you see fit. (As of version 0.42, see the
'eg/My' directory in the source distribution for the sample classes.)

Most people interested in security should not be reading the docs for
this class. Instead, look at
L<SPOPS::Manual::Security|SPOPS::Manual::Security> which offers a
broad view of security as well as how to use, implement and extend it.

=head1 METHODS

The methods that this class implements can be used by any SPOPS
class. The variable C<$item> below refers to the fact that you can
either do an object method call or a class method call. If you do a
class method call, you must pass in the ID of the object for which you
want to get or set security.

However, you may also implement security on the class level as
well. For instance, if your application uses classes to implement
modules within an application, you might wish to restrict the module
by security very similar to the security implemented for individual
objects. In this case, you would have a class name and no object ID
(C<$object_id>) value. (See
L<SPOPS::Manual::Security|SPOPS::Manual::Security> for more
information.)

=head2 check_security( [ \%params ] )

The method check_security() returns a code corresponding to the LEVEL
constants exported from this package. This code tells you what
permissions the logged in (or passed in) user has. You can pass user
and group parameters to check security for other items as well.

Note that you can check security for multiple groups but only one user
at a time. Passing an arrayref of user objects for the 'user'
parameter will result in the first user object being checked and the
remainder discarded. This is probably not what you want.

Examples:

 # Find the permission for the currently logged-in user for $item
 $item->check_security();

 # Get the security for this $item for a particuar
 # user; note that this *does* find the groups this
 # user belongs to and checks those as well

 $item->check_security({ user => $user });

 # Find the security for this item for either of the
 # groups specified

 $item->check_security({ group => [ $group, $group ] });

=head2 get_security( [ \%params ] )

Returns a hashref of security information about the particular class
or object. The keys of the hashref are the constants, SEC_SCOPE_WORLD,
SEC_SCOPE_GROUP and SEC_SCOPE_USER. The value corresponding to the
SEC_SCOPE_WORLD key is simply the WORLD permission for the object or
class. Similarly, the value of SEC_SCOPE_USER is the permission for
the user specified. The SEC_SCOPE_GROUP key has as its value
a hashref with the IDs of the group as keys. (Examples below)

Note that if the user specified does not have permissions
for the class/object, then its entry is blank.

The parameters correspond to check_security. The default is to
retrieve the security for the currently logged-in user and groups
(plus WORLD), but you can restrict the output if necessary.

Note that the WORLD key is B<always> set, no matter how much
you restrict the user/groups.

Finally: this will not be on the test, since you will probably not
need to use this very often unless you are subclassing this class to
create your own custom security checks. The C<check_security()> and
C<set_security()> methods are likely the only interfaces you need with
security whether it be object or class-based. The C<get_security()>
method is used primarily for internal purposes, but you might also
need it if you are writing security administration tools.

Examples:

 # Return a hashref using the currently logged-in
 # user and the groups the user belongs to
 #
 # Sample of what $perm looks like:
 # $perm = { 'u' => 4, 'w' => 1, 'g' => { 5162 => 4, 7182 => 8 } };
 #
 # Which means that the user has a permission of SEC_LEVEL_READ,
 # the user belongs to two groups with IDs 5162 and 7182 which have
 # permissions of READ and WRITE, respectively, and the WORLD
 # permission is NONE.
 my $perm = $item->get_security();

 # Find the security for a particular user object and its groups
 my $perm = $item->get_security({ user => $that_user });

 # Find the security for two groups, no user objects.
 my $perm = $item->get_security({ group => [ $group1, $group2 ] });

=head2 get_security_scopes( \%params )

Called by B<get_security()> to determine which user object and which
group objects to use to check security on an object.

Returns: two-item list, the first is the C<$user> object and the
second is an arrayref of C<$group> objects.

=head2 set_security( \%params )

The method set_security() returns a status as to whether the
permission has been set to what you requested.

The default is to operate on one item at a time, but you can
specify many items at once with the 'multiple' parameter.

Examples:

 # Set $item security for WORLD to READ

 my $wrv =  $item->set_security({ scope => SEC_SCOPE_WORLD,
                                  level => SEC_LEVEL_READ });
 unless ( $wrv ) {
   # error! security not set properly
 }

 # Set $item security for GROUP $group to WRITE

 my $grv =  $item->set_security({ scope => SEC_SCOPE_GROUP,
                                  scope_id => $group->id,
                                  level => SEC_LEVEL_WRITE });
 unless ( $grv ) {
   # error! security not set properly
 }

 # Set $item security for USER objects whose IDs are the keys in the
 # hash %multiple and whose values are the levels corresponding to the
 # ID.
 #
 # (Note that this is a contrived example for setting up the %multiple
 # hash - you should always do some sort of validation/checking before
 # passing user-specified information to a method.)

 my %multiple = (
  $user1->id => $cgi->param( 'level_' . $user1->id ),
  $user2->id => $cgi->param( 'level_' . $user2->id )
 );
 my $rv = $item->set_security({ scope => SEC_SCOPE_USER,
                                level => \%multiple });
 if ( $rv != scalar keys %multiple ) {
   # error! security not set properly for all items
 }

 # Set $item security for multiple scopes whose values
 # are in the hash %multiple; note that the hash %multiple
 # has a separate layer now since we're specifying multiple
 # scopes within it.

 my %multiple = (
  SEC_SCOPE_USER() => {
     $user1->id => $cgi->param( 'level_' . $user1->id ),
     $user2->id => $cgi->param( 'level_' . $user2->id ),
  },
  SEC_SCOPE_GROUP() => {
     $group1->id  => $cgi->param( 'level_group_' . $group1->id ),
  },
 );
 my $rv = $item->set_security({ scope => [ SEC_SCOPE_USER, SEC_SCOPE_GROUP ],
                                level => \%multiple });

=head2 create_initial_security( \%params )

Creates the security for a newly created object. Generally this
entails looking at the C<creation_security> key of an object
configuration and mapping the permissions there to the object.

Parameters:

=over 4

=item *

B<class>: Specify the class you want to use to create the initial
security.

=item *

B<object_id>: Specify the object ID you want to use to create the initial
security.

=back

=head1 SUPERUSER METHODS

A handful of methods enable SPOPS to implement superuser/group
checking. A superuser is a user who can perform any action, and a
member of the supergroup can do the same.

If your class does not use the supergroup, just setup a function:

 sub is_supergroup { return undef }

B<_check_superuser( $user_object, \@group_object )>

Checks whether the given user and group listing has superuser
status. Returns a hashref suitable for passing to C<check_security()>.

NOTE: We may rename this to C<check_superuser()> in the future.

B<is_superuser( $user_id )>

Returns true if C<$user_id> is the superuser, false if not. Default is
for the value C<1> to be the superuser ID, but subclasses can easily
override.

B<is_supergroup( @group_id )>

Returns true if one of C<@group_id> is the supergroup, false if
not. Default is for the value C<1> to be the supergroup ID, but
subclasses can easily override.

=head1 TAGS FOR SCOPE/LEVEL

This module exports nothing by default. You can import specific tags
that refer to the scope and level, or you can import groups of them.

Note that you should B<always> use these tags. They may seem
unwieldly, but they make your program easier to read and allow us to
modify the values for these behind the scenes without you modifying
any of your code. If you use the values directly, you will get what is
coming to you.

You can import individual tags like this:

 use SPOPS::Secure qw( SEC_SCOPE_WORLD );

Or you can import the tags in groups like this:

 use SPOPS::Secure qw( :scope );

B<Scope Tags>

=over 4

=item *

SEC_SCOPE_WORLD

=item *

SEC_SCOPE_GROUP

=item *

SEC_SCOPE_USER

=back

B<Level Tags>

=over 4

=item *

SEC_LEVEL_NONE

=item *

SEC_LEVEL_SUMMARY

=item *

SEC_LEVEL_READ

=item *

SEC_LEVEL_WRITE

=back

B<Verbose Level Tags>

These tags return a text value for the different security levels.

=over 4

=item *

SEC_LEVEL_VERBOSE_NONE (returns 'NONE')

=item *

SEC_LEVEL_VERBOSE_SUMMARY (returns 'SUMMARY')

=item *

SEC_LEVEL_VERBOSE_READ (returns 'READ')

=item *

SEC_LEVEL_VERBOSE_WRITE (returns 'WRITE')

=back

B<Groups of Tags>

=over 4

=item *

B<scope>: brings in all SEC_SCOPE tags

=item *

B<level>: brings in all SEC_LEVEL tags

=item *

B<verbose>: brings in all SEC_LEVEL_VERBOSE tags

=item *

B<all>: brings in all tags

=back

=head1 TO DO

B<Refactor create_initial_security()>

This method is too long and confusing -- break it into pieces.

B<Sort out the different set_* methods>

The different set_* methods are currently quite confusing.

B<Add caching>

Gotta gotta gotta get a caching interface done, where we simply say:

 $object->cache_security_level( $user );

And cache the security level for that object for that user. **Any**
security modifications to that object wipe out the cache for that
object.

=head1 BUGS

None known, besides girth.

=head1 COPYRIGHT

Copyright (c) 2001-2004 intes.net, inc.. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters  E<lt>chris@cwinters.comE<gt>
