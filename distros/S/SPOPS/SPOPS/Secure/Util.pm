package SPOPS::Secure::Util;

# $Id: Util.pm,v 1.6 2004/06/02 00:48:24 lachoy Exp $

use strict;
use Data::Dumper  qw( Dumper );
use Log::Log4perl qw( get_logger );
use SPOPS::Secure qw( :level :scope );

my $log = get_logger();

# Setup a hashref where w/u => security_level and g points to a
# hashref where the key is the group_id value is the security level.

sub parse_objects_into_hashref {
    my ( $class, $security_objects ) = @_;

    my %items = ( SEC_SCOPE_WORLD() => undef,
                  SEC_SCOPE_USER()  => undef,
                  SEC_SCOPE_GROUP() => {} );
    unless ( ref $security_objects eq 'ARRAY'
             and scalar @{ $security_objects } > 0 ) {
        return undef;
    }

ITEM:
    foreach my $sec ( @{ $security_objects } ) {
        if ( $sec->{scope} eq SEC_SCOPE_WORLD || $sec->{scope} eq SEC_SCOPE_USER ) {
            $items{ $sec->{scope} } = $sec->{security_level};
            $log->is_debug &&
                $log->debug( "Assign [$sec->{security_level}] to [$sec->{scope}]" );
        }
        elsif ( $sec->{scope} eq SEC_SCOPE_GROUP ) {
            $items{ $sec->{scope} }->{ $sec->{scope_id} } = $sec->{security_level};
            $log->is_debug &&
                $log->debug( "Assign [$sec->{security_level}] to ",
                            "[$sec->{scope}][$sec->{scope_id}]" );
        }
    }
    $log->is_info &&
        $log->info( "All security parsed: ", Dumper( \%items ) );;
    return \%items;
}

sub find_class_and_oid {
    my ( $class, $item, $p ) = @_;

    # First assume it's a class we're passed in to check

    my $obj_class = $p->{class} || $item;
    my $oid       = $p->{object_id} || $p->{oid} || '0';

    # If this is an object, modify lines accordingly

    if ( ref $item and UNIVERSAL::can( $item, 'id' ) ) {
        $oid        = eval { $item->id } || '0';
        $obj_class  = ref $item;
    }
    return ( $obj_class, $oid );
}


1;

__END__

=head1 NAME

SPOPS::Secure::Util - Common utilities for SPOPS::Secure and subclasses

=head1 SYNOPSIS

 my $levels = SPOPS::Secure::Util-&gt;parse_object_into_hashref( \@security_objects );
 print "Given security from objects:\n",
       "USER: $levels-&gt;{ SEC_SCOPE_USER() }\n",
       "WORLD: $levels-&gt;{ SEC_SCOPE_WORLD() }\n";
       "GROUP [ID/LEVEL]: ";
 print join( ' ', map { "[$_/$levels-&gt;{ SEC_SCOPE_GROUP() }{ $_ }" }
                      keys %{ $levels-&gt;{ SEC_SCOPE_GROUP() } } );

 # Not sure if $item is class or object?

 sub somesub {
     my ( $item, $params ) = @_;
     my ( $object_class, $object_id ) =
                         SPOPS::Secure::Util-&gt;find_class_and_oid( $item, $params );
 }

=head1 DESCRIPTION

Common utility methods for security tasks.

=head1 METHODS

All methods are class methods.

B<parse_objects_into_hashref( \@security_objects )>

Places the relevant information from C<\@security_objects> into a
hashref for easy analysis. If no objects are in C<\@security_objects>
it returns undef. Otherwise the returned hashref should have as the
three keys the constants C<SEC_SCOPE_WORLD>, C<SEC_SCOPE_GROUP> and
C<SEC_SCOPE_USER>.

The values of C<SEC_SCOPE_WORLD> and C<SEC_SCOPE_USER> are a single
value corresponding to one of the C<SEC_LEVEL_*> constants. The value
of C<SEC_LEVEL_GROUP> is another hashref with the keys as the group
IDs each of which has a single value corresponding to one of the
C<SEC_LEVEL_*> constants.

B<find_class_and_oid( [$class|$object], \%params )>

Useful when a method can be called as a class or object
method and the class/ID to be analyzed can be either in the object
calling or in the class and the parameters. 

Returns a two-argument list. The first is the object class, the second
is the object ID.

If the first argument is an object and it has a method C<id()>, we
assign the result of calling it to the object ID; for the object class
we call C<ref> on the object.

Otherwise we look in C<\%params> for a parameter 'class'. If it is not
found we use the first argument. For the object ID we
look in C<\%params> for a parameter 'object_id' or 'oid'. If neither
are found we assign '0' to the object ID.  For example:

 my $class = 'My::Object'; my ( $object_class, $object_id ) =
                    SPOPS::Secure::Util->find_class_and_oid( $class, { object_id => 5 } );
 # $object_class = 'My::Object'; $object_id = 5

 my $object = My::OtherObject->new({ id => 99 });
 my ( $object_class, $object_id ) =
                    SPOPS::Secure::Util->find_class_and_oid( $object );
 # $object_class = 'My::OtherObject'; $object_id = 99

=head1 BUGS

None known.

=head1 TO DO

Nothing known.

=head1 SEE ALSO

=head1 COPYRIGHT

Copyright (c) 2002-2004 intes.net, inc.. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters E<lt>chris@cwinters.comE<gt>
