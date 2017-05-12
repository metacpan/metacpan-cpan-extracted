package SPOPS::Secure::Hierarchy;

# $Id: Hierarchy.pm,v 3.6 2004/06/02 00:48:24 lachoy Exp $

use strict;
use base  qw( Exporter SPOPS::Secure );
use Log::Log4perl qw( get_logger );
use vars  qw( $ROOT_OBJECT_NAME );

use Data::Dumper  qw( Dumper );
use SPOPS;
use SPOPS::Exception::Security;
use SPOPS::Secure qw( :scope :level $EMPTY );
use SPOPS::Secure::Util;

my $log = get_logger();

@SPOPS::Secure::Hierarchy::EXPORT_OK = qw( $ROOT_OBJECT_NAME );
$SPOPS::Secure::Hierarchy::VERSION   = sprintf("%d.%02d", q$Revision: 3.6 $ =~ /(\d+)\.(\d+)/);

$ROOT_OBJECT_NAME = 'ROOT_OBJECT';


# Override this method from SPOPS::Secure -- return a hashref with the
# scopes as keys and the values as security information (level or
# hashref of scope_id => level)

sub get_security {
    my ( $item, $p ) = @_;

    # Find object info for debugging and for passing to the
    # fetch_by_object method later

    my ( $class, $oid ) = SPOPS::Secure::Util->find_class_and_oid( $item, $p );
    $log->is_info &&
        $log->info( "Checking security for [$class: $oid]" );

    # Punt the request back to our parent if we're getting security
    # explicitly for the ROOT_OBJECT, which generally only happens when
    # we're editing its security

    if ( $oid eq $ROOT_OBJECT_NAME ) {
        $log->is_info &&
            $log->info( "Object ID == ROOT_OBJECT_NAME: punting to parent" );
        return SUPER->get_security({ %{ $p },
                                     class     => $class,
                                     object_id => $oid });
    }

    unless ( exists $p->{user} and exists $p->{group} ) {
        ( $p->{user}, $p->{group} ) = $item->get_security_scopes( $p );
    }

    # superuser (record with user_id 1) can do anything

    if ( my $security_info = $item->_check_superuser( $p->{user}, $p->{group} ) ) {
        $log->is_info &&
            $log->info( "Superuser is logged in" );
        return $security_info;
    }

    my ( $all_levels, $first_level ) = $item->get_hierarchy_levels( $p );
    $log->is_info &&
        $log->info( "First level with security ($first_level)" );

    # Dereference $EMPTY so there's no chance of anyone putting
    # information into the ref and screwing up the package variable...

    return $all_levels->{ $first_level } || \%{ $EMPTY };
}


sub get_hierarchy_levels {
    my ( $item, $p ) = @_;

    # Grab hierarchy config info from the params or from the object

    my $object_id = $p->{oid} || $p->{object_id};
    my $h_info = $item->_get_hierarchy_parameters({ %{ $p },
                                                    hierarchy_value => $object_id });

    # Ensure we have necessary info

    unless ( $h_info->{hierarchy_value} ) {
        $log->warn( "No value available to split into hierarchy! Returning ",
                    "empty security." );
        return ();
    }
    unless ( ref $h_info->{hierarchy_manip} eq 'CODE' ) {
        $log->warn( "Cannot split hierarchy into pieces without either a ",
                    "separator or processing code. Returning empty security." );
        return ();
    }

    # Now comes the interesting part. Setup a list of the object value
    # followed by all the parents. Note that we can either use the
    # default generated list (splitting the value by the separator) or
    # create a subroutine to do it for us, passing it in via
    # 'hierarchy_manip' in the routine parameters or in our object
    # config.

    my $check_list = $h_info->{hierarchy_manip}->( $h_info->{hierarchy_sep},
                                                   $h_info->{hierarchy_value} );

    return $item->_fetch_hierarchy_levels({ %{ $p },
                                            check_list => $check_list,
                                            ordered    => 1  });
}


sub create_root_object_security {
    my ( $item, $p ) = @_;
    my ( $class, $oid ) = SPOPS::Secure::Util->find_class_and_oid( $item, $p );
    return $class->set_security({ object_id      => $ROOT_OBJECT_NAME,
                                  scope          => $p->{scope},
                                  security_level => $p->{level} });
}


# Override so that the WORLD scope doesn't get any default setting

sub create_initial_security { return 1 }


# Retrieve and store a security level for each item in the hierarchy
# check_list, returning these security levels plus a marker denoting
# the first one found. This is used not only in get_security but can
# also be useful when displaying all the parents of a particular
# object and how security is inherited.

sub _fetch_hierarchy_levels {
    my ( $item, $p ) = @_;
    my $class = $p->{class} || ref $item || $item;
    my $so_class = $p->{security_object_class} ||
                   $class->global_security_object_class;

    my $first_found = undef;
    my $level_track = {};
    my @ordered     = ();

    unless ( $p->{class} ) {
        my $object_id = $p->{oid} || $p->{object_id};
        ( $p->{class}, $p->{oid} ) = SPOPS::Secure::Util->find_class_and_oid(
                                                                      $item, $p );
        $log->is_info &&
            $log->info( "Checking security for [$p->{class}] [$p->{oid}]" );
    }

    # Yes, I know, grep in a void context...

    unless ( grep /^$ROOT_OBJECT_NAME$/, @{ $p->{check_list} } ) {
        push @{ $p->{check_list} }, $ROOT_OBJECT_NAME;
        $log->is_info &&
            $log->info( "$ROOT_OBJECT_NAME not found in checklist; added manually" );
    }

SECVALUE:
    foreach my $security_check ( @{ $p->{check_list} } ) {
        $log->is_info &&
            $log->info( "Find value for $p->{class} ($security_check)" );
        push @ordered, $security_check  if ( $p->{ordered} );
        my $sec_listing = $so_class->fetch_by_object( $p->{class},
                                                      { object_id => $security_check,
                                                        user      => $p->{user},
                                                        group     => $p->{group} });
        $log->is_info &&
            $log->info( "Security found for ($security_check):\n",
                          Dumper( $sec_listing ) );

        $first_found ||= $security_check if ( $sec_listing );
        $level_track->{ $security_check } = $sec_listing;
    }

    # If we don't find a single item that has security, we need to
    # create security for this class's root object.

    unless ( $first_found ) {
        $log->is_info &&
            $log->info( "Cannot find ANY security for [$p->{class}] [$p->{oid}] -- ",
                          "creating extremely stringent root object security" );
        $item->create_root_object_security({ class  => $p->{class},
                                             scope  => SEC_SCOPE_WORLD,
                                             level  => SEC_LEVEL_NONE });
    }
    return ( $level_track, $first_found ) unless ( $p->{ordered} );
    return ( $level_track, $first_found, \@ordered );
}


# Set the parameters for hierarchy information whether it came in
# through a parameter list or from an object and its configuration.

sub _get_hierarchy_parameters {
    my ( $item, $p ) = @_;

    # Find the hierarchy information -- info passed into the routine via
    # parameters takes precedence, and we only query the object config if
    # we actually have an object.

    my $h_info = {};
    $h_info->{hierarchy_field} = $p->{hierarchy_field};
    $h_info->{hierarchy_sep}   = $p->{hierarchy_separator};
    $h_info->{hierarchy_manip} = $p->{hierarchy_manip};

    my $class = $p->{class} || ref $item || $item;
    my $CONF = eval { $class->CONFIG };
    if ( ref $CONF ) {
        $h_info->{hierarchy_field} ||= $CONF->{hierarchy_field};
        $h_info->{hierarchy_sep}   ||= $CONF->{hierarchy_separator};
        $h_info->{hierarchy_manip} ||= $CONF->{hierarchy_manip};
    }

    # Only use the default check_list maker if there is a hierarchy
    # separator

    if ( $h_info->{hierarchy_sep} ) {
        $h_info->{hierarchy_manip} ||= \&_make_check_list;
    }

    # If this is an object, find the hierarchy value from the object

    $h_info->{hierarchy_value} = $p->{hierarchy_value};
    my $object = ( ref $item ) ? $item : $p->{object}; # this is a nasty hack
    if ( $object ) {
        $log->is_info &&
            $log->info( "Getting value from object, overriding previously ",
                        "set value of '$h_info->{hierarchy_value}'" );
        $h_info->{hierarchy_value} = $object->{ $h_info->{hierarchy_field} };
    }

    $log->is_info &&
        $log->info( "Found parameters:\n", Dumper( $h_info ) );
    return $h_info;
}


# Note: don't push the root object reference onto the stack in this
# procedure -- we handle it automatically in ->get_hierarchy_levels()

sub _make_check_list {
    my ( $hierarchy_sep, $hierarchy_value ) = @_;
    my @check_list = ( $hierarchy_value );

    # don't get into an infinite loop!
    unless ( $hierarchy_value =~ m!$hierarchy_sep! ) {
        return \@check_list;
    }

    while ( $hierarchy_value ) {
        $hierarchy_value =~ s|^(.*)$hierarchy_sep.*$|$1|;
        push @check_list, $hierarchy_value    if ( $hierarchy_value );
    }
    return \@check_list;
}

1;


__END__

=head1 NAME

SPOPS::Secure::Hierarchy - Define hierarchical security

=head1 SYNOPSIS

 # In your SPOPS configuration
 'myobj' => {
    'class' => 'My::FileObject',
    'isa' => [ qw/ ... SPOPS::Secure::Hierarchy  ... / ],
    'hierarchy_separator' => '/',
    'hierarchy_field'     => 'myobj_id',
    ...
 },

 # Every normal SPOPS security check will now go through a hierarchy
 # check using '/' as a separator on the value of the object parameter
 # 'myobj_id'

  my $file_object = eval { My::FileObject->fetch(
                             '/docs/release/devel-only/v1.3/mydoc.html' ) };

 # You can also use it as a standalone service. Note that the 'class'
 # in this example is controlled by you and used as an identifier
 # only.

 my $level = eval { SPOPS::Secure::Hierarchy->check_security({
                      class                 => 'My::Nonexistent::File::Class',
                      user                  => $my_user,
                      group                 => $my_group_list,
                      security_object_class => 'My::SecurityObject',
                      object_id             => '/docs/release/devel-only/v1.3/mydoc.html',
                      hierarchy_separator   => '/' }) };

=head1 DESCRIPTION

The existing SPOPS security framework relies on a one-to-one mapping
of security value to object. Sometimes you need security to filter
down from a parent to any number of children, such as in a
pseudo-filesystem of objects.

To accomplish this, every record needs to have an identifier that can
be manipulated into a parent identifier. With filesystems (or URLs)
this is simple. Given the pseudo-file:

 /docs/release/devel-only/v1.3/mydoc.html

You have the following parents:

 /docs/release/devel-only/v1.3
 /docs/release/devel-only
 /docs/release
 /docs
 <ROOT OBJECT> (explained below)

What this module does is check the security of each parent in the
hierarchy. If B<no> security settings are found for an item, the
module tries to find security of its parent. This continues until
either the parent hierarchy is exhausted or one of the parents has a
security setting.

If the security were defined like this:

(Note: this is pseudo-code, and not necessarily the internal
representation):

 <ROOT OBJECT> =>
      { world => SEC_LEVEL_READ,
        group => { admin => SEC_LEVEL_WRITE } }

 /docs/release/devel-only =>
      { world => SEC_LEVEL_NONE,
        group => { devel => SEC_LEVEL_WRITE } }

And our sample file is:

 /docs/release/devel-only/v1.3/mydoc.html

And our users are:

=over 4

=item *

B<racerx> is a member of groups 'public', 'devel' and 'mysteriouscharacters'

=item *

B<chimchim> is a member of groups 'public', 'sidekicks'

=item *

B<speed> is a member of groups 'public' and 'devel'

=back

Then both the users racerx and speed would have SEC_LEVEL_WRITE access
to the file while chimchim would have no access at all.

For the file:

 /docs/release/public/v1.2/mydoc.html

All three users would have SEC_LEVEL_READ access since the permissions
inherit from the C<ROOT OBJECT>.

=head2 What is the ROOT OBJECT?

If you have a hierarchy of security, you are going to need one object
from which all security flows. No matter what kind of identifiers,
separators, etc. that you are using, the root object always has the
same object ID (For the curious, this object ID is available as the
exported scalar C<$ROOT_OBJECT_NAME> from this module.)

If you do not create security for the root object manually,
C<SPOPS::Secure::Hierarchy> will do so for you. However, you should be
aware that it will create the most stringent permissions for such an
object and that you might have a difficult time creating/updating
objects once this happens.

Here is how to create such security:

 $class->create_root_object_security({
          scope => [ SEC_SCOPE_WORLD, SEC_SCOPE_GROUP ],
          level => { SEC_SCOPE_WORLD() => SEC_LEVEL_READ,
                     SEC_SCOPE_GROUP() => { 3 => SEC_LEVEL_WRITE } }
 });

Now, every object created in your class will default to having READ
permissions for WORLD and WRITE permissions for group ID 3.

=head1 METHODS

Most of the functionality in this class is found in
L<SPOPS::Secure|SPOPS::Secure>. We override one of its methods and add
another to implement the functionality of this module.

B<get_hierarchy_levels( \%params )>

Retrieve security for each level of the hierarchy. Returns a list --
the first element is a hashref with the keys as hierarchy elements and
the values as the security settings for that element (like what you
would get back if you checked only one item). The second element is a
scalar with the key of the first item encountered which actually had
security.

Example:

 my ( $all_levels, $first ) = $obj->get_hierarchy_levels();
 print "Level Info:\n", Data::Dumper::Dumper( $all_levels );

 >Level Info:
 > $VAR1 = {
 >  '/docs/release/devel-only/v1.3/mydoc.html' => undef,
 >  '/docs/release/devel-only/v1.3' => undef,
 >  '/docs/release/devel-only' => { u => 4, g => undef, w => 8 },
 >  '/docs/release/' => undef,
 >  '/docs/' => undef,
 >  'ROOT_OBJECT' => { u => undef, g => undef, w => 4 }
 >};

 print "First Level: ", $first;

 > First Level: /docs/release/devel-only

B<get_security( \%params )>

Returns: hashref of security information indexed by the scopes.

Parameters:

=over 4

=item *

B<class> ($) (not required if calling from object)

Class (or generic identifier) for which we would like to check
security

=item *

B<object_id> ($) (not required if calling from object)

Unique identifier for the object (or generic thing) needing to be
checked.

=item *

B<hierarchy_field> ($) (only required if calling from object with no
configuration)

Field to be used for the hierarchy check. Most (all?) of the time this
will be the same as your configured 'id_field' in your SPOPS
configuration.

=item *

B<hierarchy_separator> ($) (not required if calling from object with
configuration)

Character or characters used to split the hierarchy value into pieces.

=item *

B<hierarchy_manip> (optional)

Code reference that, given the value to be broken into chunks, will
return a hashref of information that describe the ways the hierarchy
information can be used.

=back

B<create_initial_security()>

This is overridden and a no-op, since we do not want
L<SPOPS::Secure|SPOPS::Secure> to create the default WORLD settings
for us and mess up our inheritance.

B<create_root_object_security( \%params )>

If you are trying to retrofit this security system into a class with
already existing objects, you will need a way to bootstrap it so that
you can perform the actions you like. This method will create initial
security for you.

Parameters:

=over 4

=item *

B<scope> (\@ or $)

One or more SPOPS::Secure C<SEC_SCOPE_*> constants that define the
scopes that you are defining security for.

=item *

B<level> (\% or $)

If you have specified more than one item in the 'scope' parameter,
this is a hashref, the keys of which are the scopes defined. The value
may be a SPOPS::Secure LEVEL constant if the matching scope is WORLD,
or a hashref of object-id - LEVEL pairs if the matching scope is USER
or GROUP. (See L<What is the ROOT OBJECT?> above.)

=back

=head1 BUGS

None known.

=head1 TO DO

B<Revisit when hierarchy field != primary key>

the _get_hierarchy_parameters has an assumption that the object ID
will always be the hierarchy value. Fix this. (Putting off because
this is unlikely.)

=head1 NOTES

B<Security for Each Parent not Required>

Note that each parent as we go up the hierarchy does not have to exist
in terms of security. That is, since an object can be both a child and
a parent, and a child can inherit from a parent, then the inheritance
needs to be able to flow through more than one generation.

=head1 SEE ALSO

L<SPOPS::Secure|SPOPS::Secure>

=head1 COPYRIGHT

Copyright (c) 2001-2004 intes.net, inc.. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters E<lt>chris@cwinters.comE<gt>

Christian Lemburg E<lt>lemburg@aixonix.deE<gt>
