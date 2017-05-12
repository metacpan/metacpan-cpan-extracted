package SPOPS::Secure::Loopback;

# $Id: Loopback.pm,v 1.5 2004/06/02 00:48:24 lachoy Exp $

use strict;
use Log::Log4perl qw( get_logger );
use SPOPS;
use SPOPS::Secure qw( :level :scope );
use SPOPS::Secure::Util;

my $log = get_logger();

$SPOPS::Secure::Loopback::VERSION = sprintf("%d.%02d", q$Revision: 1.5 $ =~ /(\d+)\.(\d+)/);

sub fetch_by_object {
    my ( $class, $object, $p ) = @_;
    my @security_objects = $class->_fetch_all_by_object( $object, $p );
    my ( @user_match, @group_match, @world_match );
    if ( $p->{user} ) {
        my $user_id = eval { $p->{user}->id };
        if ( $user_id ) {
            @user_match = $class->_filter_by_scope( SEC_SCOPE_USER, $user_id,
                                                    @security_objects );
        }
    }
    if ( ref $p->{group} eq 'ARRAY' ) {
        for ( @{ $p->{group} } ) {
            my $group_id = eval { $_->id };
            if ( $group_id ) {
                push @group_match, $class->_filter_by_scope( SEC_SCOPE_GROUP,
                                                             $group_id, @security_objects );
            }
        }
    }
    @world_match = $class->_filter_by_scope( SEC_SCOPE_WORLD, undef, @security_objects );
    return SPOPS::Secure::Util->parse_objects_into_hashref(
                         [ @user_match, @group_match, @world_match ] );
}

sub _fetch_all_by_object {
    my ( $class, $object, $p ) = @_;
    my ( $find_class, $find_id ) =
               SPOPS::Secure::Util->find_class_and_oid( $object, $p );
    return () unless ( $find_class and $find_id );
    my $all_class_security = $class->fetch_group({
                                        where => "class = $find_class" });
    my @security_objects = ();
    for ( @{ $all_class_security } ) {
        next unless ( $_->{object_id} );
        if ( $_->{object_id} eq $find_id ) {
            push @security_objects, $class->new( $_ );
        }
    }
    return @security_objects;
}

sub fetch_match {
    my ( $class, $object, $p ) = @_;
    return undef  unless ( $p->{scope} );
    my $is_world = 1 if ( $p->{scope} eq SEC_SCOPE_WORLD );
    return undef  unless ( $is_world or $p->{scope_id} );
    my @security_objects = $class->_fetch_all_by_object( $object, $p );
    return ( $class->_filter_by_scope( $p->{scope}, $p->{scope_id}, @security_objects) )[0];
}

sub _filter_by_scope {
    my ( $class, $scope, $scope_id, @objects ) = @_;
    my $is_world = 1   if ( $scope eq SEC_SCOPE_WORLD );
    my @matching = ();
    for ( @objects ) {
        next unless ( $_->{scope} eq $scope );
        if ( $is_world or ( $_->{scope_id} eq $scope_id ) ) {
            push @matching, $_;
        }
    }
    return @matching;
}

1;

__END__

=head1 NAME

SPOPS::Secure::Loopback - Security object implementation for testing (loopback) objects

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

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
