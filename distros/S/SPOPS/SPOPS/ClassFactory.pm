package SPOPS::ClassFactory;

# $Id: ClassFactory.pm,v 3.6 2004/06/02 00:48:21 lachoy Exp $

use strict;
use base  qw( Exporter );
use Log::Log4perl qw( get_logger );

use Class::ISA;
use Data::Dumper  qw( Dumper );
use SPOPS;
use SPOPS::Exception;

$SPOPS::ClassFactory::VERSION   = sprintf("%d.%02d", q$Revision: 3.6 $ =~ /(\d+)\.(\d+)/);
@SPOPS::ClassFactory::EXPORT_OK = qw( OK DONE NOTIFY ERROR RESTART
                                      FACTORY_METHOD RULESET_METHOD );

use constant OK             => 'OK';
use constant DONE           => 'DONE';
use constant NOTIFY         => 'NOTIFY';
use constant ERROR          => 'ERROR';
use constant RESTART        => 'RESTART';
use constant FACTORY_METHOD => 'behavior_factory';
use constant RULESET_METHOD => 'ruleset_factory';

my $log = get_logger();

my %REQ_CLASSES = ();

my $PK = '__private__'; # Save typing...

# TODO: Export constants with the names of these slots -- the order
# doesn't matter to anyone except us, so we shouldn't need to export
# order and be able to keep the variable a lexical

my @SLOTS = qw(
  manipulate_configuration id_method read_code
  fetch_by has_a links_to add_rule
);

my %SLOT_NUM = map { $SLOTS[ $_ ] => $_ } ( 0 .. ( scalar @SLOTS - 1 ) );


########################################
# MAIN INTERFACE
########################################

# TODO: Will $config ever be an object? Also, is 'create' the best
# name?

sub create {
    my ( $class, $all_config, $p ) = @_;
    return [] unless ( ref $all_config eq 'HASH' );
    $p ||= {};

    $class->create_all_stubs( $all_config, $p );
    $class->find_all_behavior( $all_config, $p );
    $class->exec_all_behavior( $all_config, $p );
    $class->clean_all_behavior( $all_config, $p );

    my $alias_list = $class->get_alias_list( $all_config, $p );
    return [ map { $all_config->{ $_ }->{class} }
                 grep { defined $all_config->{ $_ }->{class} }
                      @{ $alias_list } ];
}


########################################
# MULTI-CONFIG METHODS
########################################

# These methods operate on $all_config, a hashref of SPOPS
# configuration hashrefs


# First, we need to create the class so we can have an inheritance
# tree to walk -- think of this as the ur-behavior, or the beginning
# of the chicken-and-egg, or...

sub create_all_stubs {
    my ( $class, $all_config, $p ) = @_;
    my $alias_list = $class->get_alias_list( $all_config, $p );
    foreach my $alias ( @{ $alias_list } ) {
        my $this_class = $all_config->{ $alias }{class};
        $all_config->{ $alias }->{main_alias} ||= $alias;
        my ( $status, $msg ) = $class->create_stub( $all_config->{ $alias } );
        if ( $status eq ERROR )     { SPOPS::Exception->throw( $msg ) }
        my ( $cfg_status, $cfg_msg ) = $class->install_configuration( $this_class, $all_config->{ $alias } );
        if ( $cfg_status eq ERROR ) { SPOPS::Exception->throw( $cfg_msg ) }
    }
}


# Now that the class is created with at least @ISA defined, we can
# walk through @ISA for each class and install all the behaviors

sub find_all_behavior {
    my ( $class, $all_config, $p ) = @_;
    my $alias_list = $class->get_alias_list( $all_config, $p );
    foreach my $alias ( @{ $alias_list } ) {
        my $this_class = $all_config->{ $alias }{class};
        my $this_config = $this_class->CONFIG;
        $this_config->{ $PK }{behavior_table} = {};
        $this_config->{ $PK }{behavior_run}   = {};
        $this_config->{ $PK }{behavior_map}   = $class->find_behavior( $this_class );
    }
}


# Now execute the behavior for each slot-and-alias. Note that we
# cannot do this in reverse order (alias-and-slot) because some later
# slots (particularly the relationship ones) may depend on earlier
# slots being executed for other classes.

sub exec_all_behavior {
    my ( $class, $all_config, $p ) = @_;
    my $alias_list = $class->get_alias_list( $all_config, $p );
    foreach my $slot_name ( @SLOTS ) {
        foreach my $alias ( @{ $alias_list } ) {
            my $this_class = $all_config->{ $alias }{class};
            $class->exec_behavior( $slot_name, $this_class );
        }
    }
}


# Remove all evidence of behaviors, tracking, etc. -- nobody should
# need this information once the class has been created.

sub clean_all_behavior {
    my ( $class, $all_config, $p ) = @_;
    my $alias_list = $class->get_alias_list( $all_config, $p );
    foreach my $alias ( @{ $alias_list } ) {
        my $this_class = $all_config->{ $alias }{class};
        delete $this_class->CONFIG->{ $PK };
    }
}


########################################
# CREATE CLASS
########################################

# EVAL'ABLE PACKAGE/SUBROUTINES

# Here's our template for a module on the fly. Super easy.

my $GENERIC_TEMPLATE = <<'PACKAGE';
       @%%CLASS%%::ISA     = qw( %%ISA%% );
       $%%CLASS%%::C       = {};
       sub %%CLASS%%::CONFIG  { return $%%CLASS%%::C; }
PACKAGE

sub create_stub {
    my ( $class, $config ) = @_;

    my $this_class = $config->{class};
    $log->is_debug &&
        $log->debug( "Creating stub ($this_class) with main alias ($config->{main_alias})");

    # Create the barest information forming the class; just substitute our
    # keywords (currently only the class name) for the items in the
    # generic template above.

    my $module      = $GENERIC_TEMPLATE;
    $module        =~ s/%%CLASS%%/$this_class/g;
    my $isa_listing = join( ' ', @{ $config->{isa} } );
    $module        =~ s/%%ISA%%/$isa_listing/g;

    $log->is_debug &&
        $log->debug( "Trying to create class with the code:\n$module\n" );

    # Capture 'warn' calls that get triggered as a result of warnings,
    # redefined subroutines or whatnot; these get dumped to STDERR and
    # we want to be as quiet as possible -- or at least control our
    # noise!

    {
        local $SIG{__WARN__} = sub { return undef };
        eval $module;
        if ( $@ ) {
            return ( ERROR, "Error creating stub class [$this_class] with " .
                            "code\n$module\nError: $@" );
        }
    }
    return $class->require_config_classes( $config );
}


# Just step through @{ $config->{isa} } and 'require' each entry
# unless it's already been; also require everything in
# @{ $config->{rules_from} }

sub require_config_classes {
    my ( $class, $config ) = @_;
    my $this_class = $config->{class};
    my $rules_from = $config->{rules_from} || [];
    foreach my $req_class ( @{ $config->{isa} }, @{ $rules_from } ) {
        next unless ( $req_class );
        next if ( $REQ_CLASSES{ $req_class } );
        eval "require $req_class";
        if ( $@ ) {
            return ( ERROR, "Error requiring class [$req_class] from ISA " .
                            "or 'rules_from' in [$this_class]: $@" );
        }
        $log->is_debug &&
            $log->debug( "Class [$req_class] require'd by [$this_class] ok." );
        $REQ_CLASSES{ $req_class }++;
    }
    return ( OK, undef );
}


########################################
# INSTALL CONFIGURATION
########################################

# Just take the config from the $all_config (or wherever) and install
# it to the class -- we aren't doing any manipulation or anything,
# just copying over the original config key by key. Manipulation comes later.

sub install_configuration {
    my ( $class, $this_class, $config ) = @_;
    $log->is_info &&
        $log->info( "Installing configuration to class ($this_class)" );
    $log->is_debug &&
        $log->debug( "Config ($this_class)\n", Dumper( $config ) );
    my $class_config = $this_class->CONFIG;
    while ( my ( $k, $v ) = each %{ $config } ) {
        $class_config->{ $k } = $v;
    }
    return ( OK, undef );
}


########################################
# FIND BEHAVIOR
########################################

# Find all the factory method-generators in all members of a class's
# ISA, then run each of the generators and keep track of the slots
# each generator uses (behavior map)

sub find_behavior {
    my ( $class, $this_class ) = @_;
    my $this_config = $this_class->CONFIG;

    # Allow config to specify ClassFactory-only classes in
    # 'rules_from' configuration key.

    my $rule_classes = $this_config->{rules_from} || [];
    my $subs = $class->find_parent_methods( $this_class, $rule_classes, FACTORY_METHOD );
    my %behavior_map = ();
    foreach my $sub_info ( @{ $subs } ) {
        my $behavior_gen_class = $sub_info->[0];
        my $behavior_gen_sub   = $sub_info->[1];
        next if ( defined $behavior_map{ $behavior_gen_class } );

        # Execute the behavior factory and map the returned
        # information (slot => coderef or slot => \@( coderef )) into
        # the class config.

        my $behaviors = $behavior_gen_sub->( $this_class ) || {};
        $log->is_debug &&
            $log->debug( "Behaviors returned for ($this_class): ",
                          join( ', ', keys %{ $behaviors } ) );
        foreach my $slot_name ( keys %{ $behaviors } ) {
            my $typeof = ref $behaviors->{ $slot_name };
            next unless ( $typeof eq 'CODE' or $typeof eq 'ARRAY' );
            $log->is_debug &&
                $log->debug( "Adding slot behaviors for ($slot_name)" );
            if ( $typeof eq 'CODE' ) {
                push @{ $this_config->{ $PK }{behavior_table}{ $slot_name } },
                            $behaviors->{ $slot_name };
            }
            elsif ( $typeof eq 'ARRAY' ) {
                next unless ( scalar @{ $behaviors->{ $slot_name } } );
                push @{ $this_config->{ $PK }{behavior_table}{ $slot_name } },
                            @{ $behaviors->{ $slot_name } };
            }
            $behavior_map{ $behavior_gen_class }->{ $slot_name }++;
        }
    }
    return \%behavior_map;
}


# Find all instances of method $method supported by classes in the ISA
# of $class as well as in \@added_classes. Hooray for Class::ISA!

sub find_parent_methods {
    my ( $class, $this_class, $added_classes, @method_list ) = @_;
    return [] unless ( $this_class );
    unless ( ref $added_classes eq 'ARRAY' ) {
        $added_classes = [];
    }
    my @all_classes = ( @{ $added_classes },
                        Class::ISA::self_and_super_path( $this_class ) );
    my @subs = ();
    foreach my $check_class ( @all_classes ) {
        no strict 'refs';
        my $src = \%{ $check_class . '::' };
METHOD:
        foreach my $method ( @method_list ) {
            if ( defined( $src->{ $method } ) and
                 defined( my $sub = *{ $src->{ $method } }{CODE} ) ) {
                push @subs, [ $check_class, $sub ];
                $log->is_debug &&
                    $log->debug( "($this_class): Found ($method) in class ($check_class)" );
                last METHOD;
            }
        }
    }
    return \@subs;
}


########################################
# EXECUTE BEHAVIOR
########################################


# Execute behavior rules for a particular SPOPS class and slot configuration

sub exec_behavior {
    my ( $class, $slot_name, $this_class ) = @_;
    my $this_config = $this_class->CONFIG;

    # Grab the behavior list and see how many there are to execute; if
    # none, then we're all done with this slot

    my $behavior_list = $this_config->{ $PK }{behavior_table}{ $slot_name };
    return 1 unless ( ref $behavior_list eq 'ARRAY' );
    my $num_behaviors = scalar @{ $behavior_list };
    return 1 unless ( $num_behaviors > 0 );
    $log->is_debug &&
        $log->debug( "# behaviors in ($this_class)($slot_name): $num_behaviors" );

    # Cycle through the behaviors for this slot. Note that they are
    # currently unordered -- that is, the order shouldn't
    # matter. (Whether this is true remains to be seen...)

BEHAVIOR:
    foreach my $behavior ( @{ $behavior_list } ) {

        $log->is_debug &&
            $log->debug( "Running behavior for slot ($slot_name) and class ($this_class)" );

        # If this behavior has already been run, then skip it. This
        # becomes relevant when we get a RESTART status from one of
        # the behaviors (below)

        if ( $this_config->{ $PK }{behavior_run}{ $behavior } ) {
            $log->is_debug &&
                $log->debug( "Skipping behavior, already run." );
            next BEHAVIOR;
        }
        # Every behavior should return a two-element list with the
        # status and (potentially empty) message

        my ( $status, $msg ) = $behavior->( $this_class );
        $log->is_info &&
            $log->info( "Status returned from behavior: ($status)" );

        if ( $status eq ERROR ) {
            SPOPS::Exception->throw( "Cannot run behavior in [$slot_name] [$this_class]: $msg" );
        }

        # If anything but an error, go ahead and mark this behavior as
        # run. Note that we rely on coderefs always stringifying to
        # the same memory location. (This is a safe assumption, I think.)

        $this_config->{ $PK }{behavior_run}{ $behavior }++;

        # A 'DONE' means the behavior has decreed that no more
        # processing should be done in this slot

        return 1       if ( $status eq DONE );

        # An 'OK' is normal -- either the behavior declined to do
        # anything or did what it was supposed to do without issue

        next BEHAVIOR  if ( $status eq OK );

        if ( $status eq NOTIFY ) {
            warn join( "\n", "WARNING executing $slot_name for $this_config->{class}",
                             "$msg",
                             'Process will continue' ), "\n";
            next BEHAVIOR;
        }

        # RESTART is a little tricky. A 'RESTART' means that we need
        # to re-check this class for new behaviors. If we don't find
        # any new ones, no problem. If we do find new ones, then we
        # need to then re-run all behavior slots before this one. Note
        # that we will *NOT* re-run behaviors that have already been
        # run -- we're tracking them in 'behavior_run'

        if ( $status eq RESTART ) {
            $class->sync_isa( $this_class );
            my $new_behavior_map = $class->find_behavior( $this_class );
            my $behaviors_same   = $class->compare_behavior_map(
                                                     $new_behavior_map,
                                                     $this_config->{ $PK }{behavior_map} );
            next BEHAVIOR if ( $behaviors_same );
            $log->is_debug &&
                $log->debug( "Behaviors changed after receiving RESTART; re-running",
                              "from slot ($SLOTS[0]) to ($slot_name)" );
            $this_config->{ $PK }{behavior_map} = $new_behavior_map;
            for ( my $i = 0; $i <= $SLOT_NUM{ $slot_name }; $i++ ) {
                $class->exec_behavior( $SLOTS[ $i ], $this_class );
            }
        }
    }
    return 1;
}


# Sync $this_class::ISA with $this_class->CONFIG->{isa}

sub sync_isa {
    my ( $class, $this_class ) = @_;
    my $config_isa = $this_class->CONFIG->{isa};
    no strict 'refs';
    @{ $this_class . '::ISA' } = @{ $config_isa };
    $log->is_debug &&
        $log->debug( "ISA for ($this_class) synched, now: ", join( ', ', @{ $config_isa } ) );
    my ( $status, $msg ) = $class->require_config_classes( $this_class->CONFIG );
    if ( $status eq ERROR ) { SPOPS::Exception->throw( $msg ) }
    return 1;
}


# Return false if the two behavior maps don't compare (in both
# directions), true if they do

sub compare_behavior_map {
    my ( $class, $b1, $b2 ) = @_;
    return undef unless ( $class->_compare_behaviors( $b1, $b2 ) );
    return undef unless ( $class->_compare_behaviors( $b2, $b1 ) );
    return 1;
}


# Return false if all classes and slot names of behavior-1 are not in
# behavior-2

sub _compare_behaviors {
    my ( $class, $b1, $b2 ) = @_;
    return undef unless ( ref $b1 eq 'HASH' and ref $b2 eq 'HASH' );
    foreach my $b1_class ( keys %{ $b1 } ) {
        return undef unless ( $b2->{ $b1_class } );
        next if ( ! $b1->{ $b1_class } and ! $b2->{ $b1_class } );
        return undef if ( ref $b1->{ $b1_class } ne 'HASH' or ref $b2->{ $b1_class } ne 'HASH' );
        foreach my $b1_slot_name ( keys %{ $b1->{ $b1_class } } ) {
            return undef unless ( $b2->{ $b1_class }{ $b1_slot_name } );
        }
    }
    return 1;
}


########################################
# UTILITY METHODS
########################################

sub get_alias_list {
    my ( $class, $all_config, $p ) = @_;
    return [ grep ! /^_/,
                  ( ref $p->{alias_list} eq 'ARRAY' and scalar @{ $p->{alias_list} } )
                    ? @{ $p->{alias_list} }
                    : keys %{ $all_config } ];
}

1;

__END__


=head1 NAME

SPOPS::ClassFactory - Create SPOPS classes from configuration and code

=head1 SYNOPSIS

 # Using SPOPS::Initialize (strongly recommended)
 
 my $config = { ... };
 SPOPS::Initialize->process({ config => $config });
 
 # Using SPOPS::ClassFactory
 
 my $config = {};
 my $classes_created = SPOPS::ClassFactory->create( $config );
 foreach my $class ( @{ $classes_created } ) {
     $class->class_initialize();
 }

=head1 DESCRIPTION

This class creates SPOPS classes. It replaces C<SPOPS::Configure> --
if you try to use C<SPOPS::Configure> you will (for the moment) get a
warning about using a deprecated interface and call this module, but
that will not last forever.

See L<SPOPS::Manual::CodeGeneration|SPOPS::Manual::CodeGeneration> for
a discussion of what this module does and how you can customize it.

=head1 METHODS

B<create( \%multiple_config, \%params )>

Before you read on, are you sure you need to learn more about this
process? If you are just using SPOPS (as opposed to extending it), you
almost certainly want to look at
L<SPOPS::Initialize|SPOPS::Initialize> instead since it hides all
these machinations from you.

So, we can now assume that you want to learn about how this class
works. This is the main interface into the class factory, and
generally the only one you will probably ever need. Other methods in
the class factory rely on configuration information in the object or
on particular methods ('behavior generators') in the object or the
parents of the object to provide the actions for the class factory to
process.

Return value is an arrayref of classes created;

The first parameter is a series of SPOPS configurations, in the
format:

 { alias => { ... },
   alias => { ... },
   alias => { ... } }

The second parameter is a hashref of options. Currently there is only
one option supported, but the future could bring more options. Options
right now:

=over 4

=item *

B<alias_list> (\@) (optional)

List of aliases to process from C<\%multiple_config>. If not given we
simply read the keys of C<\%multiple_config>, screening out those that
begin with '_'.

Use this if you only want to process a limited number of the SPOPS
class definitions available in C<\%multiple_config>.

=back

=head2 Individual Configuration Methods

B<find_behavior( $class )>

Find all the factory method-generators in all members of the
inheritance tree for an SPOPS class, then run each of the generators
and keep track of the slots each generator uses, a.k.a. the behavior
map.

Return value is the behavior map, a hashref with keys as class names
and values as arrayrefs of slot names. For instance:

 my $b_map = SPOPS::ClassFactory->find_behavior( 'My::SPOPS' );
 print "Behaviors retrieved for My::SPOPS\n";
 foreach my $class_name ( keys %{ $b_map } ) {
     print "  -- Retrieved from ($class_name): ",
           join( ', ' @{ $b_map->{ $class_name } } ), "\n";
 }

B<exec_behavior( $slot_name, $class )>

Execute behavior rules in slot C<$slot_name> collected by
C<find_behavior()> for C<$class>.

Executing the behaviors in a slot succeeds if there are no behaviors
to execute or if all the behaviors execute without returning an
C<ERROR>.

If a behavior returns an C<ERROR>, the entire process is stopped and a
L<SPOPS::Exception|SPOPS::Exception> object is thrown with the message
returned from the behavior.

If a behavior returns a C<RESTART>, we re-find all behaviors for the
class and if they do not match up with what was found earlier, run the
behaviors that were not previously run before.

For instance, if a behavior changes the C<@ISA> of a class (by
modifying the C<{isa}> configuration key), we need to check that class
to see if it has any additional behaviors for our class. In theory,
you could get into some hairy situations with this recursion -- e.g.,
two behaviors keep adding each other -- but practically it will rarely
occur. (At least we hope so.)

Return value: true if success, throws
L<SPOPS::Exception|SPOPS::Exception> on failure.

B<create_stub( \%config )>

Creates the class specified by C<\%config>, sets its C<@ISA> to what
is set in C<\%config> and ensures that all members of the C<@ISA> are
C<require>d.

Return value: same as any behavior (OK or ERROR/NOTIFY plus message).

B<require_config_classes( \%config )>

Runs a 'require' on all members of the 'isa' and 'rules_from' keys in
C<\%config>.

Return value: same as a behavior (OK or ERROR/NOTIFY plus message).

B<install_configuration( $class, \%config )>

Installs the configuration C<\%config> to the class C<$class>. This is
a simple copy and we do not do any transformation of the data.

Return value: same as a behavior (OK or ERROR/NOTIFY plus message).

=head2 Multiple Configuration Methods

These methods are basically wrappers around the L<Individual
Configuration Methods> below, calling them once for each class to be
configured.

B<create_all_stubs( \%multiple_config, \%params )>

Creates all the necessary classes and installs the available
configuration to each class.

Calls C<create_stub()> and C<install_configuration()>.

B<find_all_behavior( \%multiple_config, \%params )>

Retrieves behavior routines from all necessary classes.

Calls C<find_behavior()>.

B<exec_all_behavior( \%multiple_config, \%params )>

Executes behavior routines in all necessary classes.

Calls C<exec_behavior()>

B<clean_all_behavior( \%multiple_config, \%params )>

Removes behavior routines and tracking information from the
configuration of all necessary classes.

Calls: nothing.

=head2 Utility Methods

B<get_alias_list( \%multiple_config, \%params )>

Looks at the 'alias_list' key in C<\%params> for an arrayref of
aliases; if it does not exist, pulls out the keys in
C<\%multiple_config> that do not begin with '_'.

Returns: arrayref of alias names.

B<find_parent_methods( $class, \@added_classes, @method_list )>

Walks through the inheritance tree for C<$class> as well as each of
the classes specified in C<\@added_classes> and finds all instances of
any member of C<@method_list>. The first match wins, and only one
match will be returned per class.

Returns: arrayref of two-element arrayrefs describing all the places
that $method_name can be executed in the inheritance tree; the first
item is the class name, the second a code reference.

Example:

 my $parent_info = SPOPS::ClassFactory->find_parent_methods(
                            'My::Class', [], 'method_factory', 'method_generate' );
 foreach my $method_info ( @{ $parent_info } ) {
     print "Class $method_info->[0] found sub which has the result: ",
           $method_info->[1]->(), "\n";
 }

B<sync_isa( $class )>

Synchronize the C<@ISA> in C<$class> with the C<{isa}> key in its
configuration. Also C<require>s all classes in the newly synchronized
C<@ISA>.

Returns true if there are no problems, throws a
L<SPOPS::Exception|SPOPS::Exception> object otherwise. (The only
reason it would fail is if a recently added class cannot be
C<require>d.)

B<compare_behavior_map( \%behavior_map, \%behavior_map )>

Returns true if the two are equivalent, false if not.

=head1 BUGS

None known (beyond being somewhat confusing).

=head1 TO DO

Nothing known.

=head1 SEE ALSO

L<SPOPS::Manual::CodeGeneration|SPOPS::Manual::CodeGeneration>

L<SPOPS|SPOPS>

=head1 COPYRIGHT

Copyright (c) 2001-2004 intes.net, inc.. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters E<lt>chris@cwinters.comE<gt>
