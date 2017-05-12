package SPOPS::Secure::DBI;

# $Id: DBI.pm,v 1.9 2004/06/02 00:48:24 lachoy Exp $

use strict;
use Log::Log4perl qw( get_logger );
use Data::Dumper  qw( Dumper );
use SPOPS;
use SPOPS::Secure qw( :level :scope );
use SPOPS::Secure::Util;

my $log = get_logger();

$SPOPS::Secure::DBI::VERSION = sprintf("%d.%02d", q$Revision: 1.9 $ =~ /(\d+)\.(\d+)/);

# Pass in:
#  $class->fetch_by_object( $obj, [ { user  => $user_obj,
#                                     group => \@( $group_obj, $group_obj, ... ) } ] );
#
# Returns:
#  hashref with world, group, user as keys (set to SEC_LEVEL_WORLD, ... ?)
#  and permissions as values; group set to hashref (gid => security_level)
#  while world/user are scalars. Note that even if you restrict the results to
#  a user and/or groups, you will always get a result back for WORLD.

sub fetch_by_object {
    my ( $class, $item, $p ) = @_;
    my ( $find_class, $find_id ) =
               SPOPS::Secure::Util->find_class_and_oid( $item, $p );
    unless ( $find_class and defined $find_id ) { # $find_id could be 0...
        my $msg = 'Cannot check security';
        warn " -- Cannot retrieve security since no item passed in to check!\n";
        SPOPS::Exception->throw( 'No item defined to check security for' );
    }

    my $where = 'class = ? AND object_id = ? AND ( scope = ?';
    my @value = ( $find_class, $find_id, SEC_SCOPE_WORLD );

    # Setup the group and user search clauses

    my ( $group_where, $group_value ) = $class->_build_group_sql( $p );
    if ( $group_where )             { $where .= " OR $group_where " }
    if ( scalar @{ $group_value } ) { push @value, @{ $group_value } }

    my ( $user_where, $user_value )   = $class->_build_user_sql( $p );
    if ( $user_where )              { $where .= " OR $user_where  " }
    if ( scalar @{ $user_value } )  { push @value, @{ $user_value } }

    $where .= ')';
    $log->is_debug &&
        $log->debug( "Security searching clause: $where\nwith values ",
                    join( '//', @value ) );

    # Fetch the objects

    my $sec_list = $class->fetch_group({ where => $where,
                                         value => \@value });
    return SPOPS::Secure::Util->parse_objects_into_hashref( $sec_list );
}


# Setup the SQL for the groups passed in

sub _build_group_sql {
    my ( $class, $p ) = @_;

    # See if we were actually given any groups or the instruction to
    # get ALL group security

    my $num_groups = ( ref $p->{group} eq 'ARRAY' )
                       ? scalar @{ $p->{group} } : 0;
    unless ( $num_groups or $p->{group} eq 'all' ) {
        $log->is_debug &&
            $log->debug( "No groups passed in, returning empty info for group SQL" );
        return ( undef, [] );
    }

    # Include the overall group clause unless we specified we want
    # 'none' of the groups

    my $where = ' ( scope = ? ';
    my @value = ( SEC_SCOPE_GROUP );

  # Only specify the actual groups we want if $p->{group} is either a
  # group object or an arrayref of group objects

    if ( ref $p->{group} ) {
        my $group_list = ( ref $p->{group} eq 'ARRAY' )
                           ? $p->{group} : [ $p->{group} ];
        if ( scalar @{ $group_list } ) {
            $log->is_debug &&
                $log->debug( scalar @{ $group_list }, " groups found passed in" );
            $where .= ' AND ( ';
            foreach my $group ( @{ $group_list } ) {
                next unless ( $group );
                $where .= ' scope_id = ? OR ';
                my $gid = ( ref $group ) ? $group->id : $group;
                push @value, $gid;
            }
            $where =~ s/ OR $/\) /;
            $where =~ s/AND \(\s*$//;
        }
    }
    $where .= ' ) '  if ( $where );
    $log->is_debug &&
        $log->debug( "Group WHERE clause: { $where }" );
    return ( $where, \@value );
}


# Setup the SQL for the user passed in

sub _build_user_sql {
    my ( $class, $p ) = @_;
    my ( $where );
    my ( @value );
    return ( $where, \@value ) unless ( $p->{user} );

    # Note that we can only do one user at a time. The caller of this
    # routine should ensure that $p->{user} is a single user object or
    # user_id.

    my $uid = ( ref $p->{user} ) ? $p->{user}->id : $p->{user};
    $where = ' ( scope = ? AND scope_id = ? )';
    push @value, SEC_SCOPE_USER, $uid;

    $log->is_debug &&
        $log->debug( "User WHERE clause: { $where }" );
    return ( $where, \@value );
}


# Pass in:
#  $class->fetch_match( $obj, { scope => SCOPE, scope_id => $id } );
#
# Returns
#  security object that matches the object, scope and scope_id,
#  undef if no match

sub fetch_match {
    my ( $class, $item, $p ) = @_;
    return undef  unless ( $p->{scope} );
    my $is_world = 1 if ( $p->{scope} eq SEC_SCOPE_WORLD );
    return undef  unless ( $is_world or $p->{scope_id} );

    my ( $find_class, $find_id ) =
               SPOPS::Secure::Util->find_class_and_oid( $item, $p );
    $p->{scope_id} ||= '';
    $log->is_info &&
        $log->info( "Try to find match for [$find_class] [$find_id] ",
                    "scope [$p->{scope}] [$p->{scope_id}]" );

    my $where  = " class = ? AND object_id = ? AND scope = ? ";
    my @values = ( $find_class, $find_id, $p->{scope} );
    unless ( $is_world ) {
        $where .= " AND scope_id = ? ";
        push @values, $p->{scope_id};
    }

    # Note that we want to keep most of the db settings from SQLInterface
    # if there's an error, so we just override the user_msg with the
    # canned error message below.

    my $row = $class->db_select({ select => [ $class->id_field ],
                                  from   => [ $class->table_name ],
                                  where  => $where,
                                  value  => \@values,
                                  return => 'single' });
    return undef unless ( $row->[0] );
    return $class->fetch( $row->[0] );
}


1;

__END__

=head1 NAME

SPOPS::Security::DBI - Implement a security object and basic operations for DBI datasources

=head1 SYNOPSIS

 # Define your implementation and create the class

 my %config = (
   'security' => {
      class          => 'My::Security',
      isa            => [ 'SPOPS::Secure::DBI', 'SPOPS::DBI' ],
      rules_from     => [ 'SPOPS::Tool::DBI::DiscoverField' ],
      field_discover => 'yes',
      field          => [],
      id_field       => 'sid',
      increment_field => 1,
      sequence_name  => 'sp_security_seq',
      no_insert      => [ qw/ sid / ],
      skip_undef     => [ qw/ object_id scope_id / ],
      no_update      => [ qw/ sid object_id class scope scope_id / ],
      base_table     => 'spops_security',
      sql_defaults   => [ qw/ object_id scope_id / ],
   },
 );

 SPOPS::Initialize->process({ config => \%config });

 # Create a security object with security level WRITE for user $user
 # on object $obj

 my $sec = My::Security->new();
 $sec->{class}          = ref $obj;
 $sec->{object_id}      = $obj->id;
 $sec->{scope}          = SEC_SCOPE_USER;
 $sec->{scope_id}       = $user->id;
 $sec->{security_level} = SEC_LEVEL_WRITE;
 $sec->save;

 # Clone that object and change its scope to GROUP and level to READ

 my $secg = $sec->clone({ scope          => SEC_SCOPE_GROUP,
                          scope_id       => $group->id,
                          security_level => SEC_LEVEL_READ });
 $secg->save;

 # Find security settings for a particular object ($spops) and user

 my $settings = My::Security->fetch_by_object(
                                        $spops,
                                        { user => [ $user ] } );
 foreach my $scope ( keys %{ $settings } ) {
   print "Security for scope $scope: $settings{ $scope }\n";
 }

 # See if there are any security objects protecting a particular SPOPS
 # object ($spops) related to a particular user (this isn't used as
 # often as 'fetch_by_object')

 use SPOPS::Secure qw( SEC_SCOPE_USER );

 my $sec_obj = My::Security->fetch_match( $spops,
                                          { scope    => SEC_SCOPE_USER,
                                            scope_id => $user->id } );

=head1 DESCRIPTION

This class implements the methods necessary to create a DBI datastore
for security objects. See
L<SPOPS::Manual::Security|SPOPS::Manual::Security> for a definition of
the interface in broader terms.

Each security setting to an object is itself an object. In this manner
we can use the SPOPS framework to create/edit/remove security
settings. (Note that if you modify this class to use 'SPOPS::Secure'
in its @ISA, you will probably collapse the Earth -- or at least your
system -- in a self-referential object definition cycle. Do not do
that.)

=head1 METHODS

B<fetch_by_object( $obj, [ { user =E<gt> \@, group =E<gt> \@ } ] )>

Returns a hashref with security information for a particular
object. The keys of the hashref are SEC_SCOPE_WORLD, 
SEC_SCOPE_USER, and SEC_SCOPE_GROUP as exported by SPOPS::Secure. 

You can restrict the security returned for USER and/or GROUP by
passing an arrayref of objects or ID values under the 'user' or
'group' keys.

Examples:

 my \%info = $sec->fetch_by_object( $obj );

Returns all security information for $obj.

 my \%info = $sec->fetch_by_object( $obj, { user  => 2,
                                            group => [ 817, 901, 716 ] } );

Returns $obj security information for WORLD, USER 2 and GROUPs 817,
901, 716.

 my $current_user = My::Object->global_user_current;
 my \%info = $sec->fetch_by_object( undef, { class     => 'My::Object',
                                             object_id => 'dandelion',
                                             user      => $user,
                                             group     => $user->group } );

Returns security information for the object of class C<My::Object>
with the ID C<dandelion> for the current user and the user's groups.

B<fetch_match( $obj, { scope =E<gt> SCOPE, scope_id =E<gt> $ } )>

Returns a security object matching the $obj for the scope and scope_id
passed in, undef if none found.

Examples:

 my $sec_class = 'My::Security';

 # Returns security object matching $obj with a scope of WORLD

 my $secw = $sec_class->fetch_match( $obj,
                                     { scope => SEC_SCOPE_WORLD } );

 # Returns security object matching $obj with a scope of GROUP
 # matching the ID from $group
 my $secg = $sec_class->fetch_match( $obj,
                                     { scope    => SEC_SCOPE_GROUP,
                                       scope_id => $group->id } );

 # Returns security object matching $obj with a scope of USER
 # matching the ID from $user
 my $secg = $sec_class->fetch_match( $obj, scope => SEC_SCOPE_USER,
                                     scope_id => $user->id );

=head1 TO DO

Nothing known.

=head1 BUGS

None known.

=head1 COPYRIGHT

Copyright (c) 2001-2004 intes.net, inc.. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters E<lt>chris@cwinters.comE<gt>
