package SecurityCommon;

use strict;

my ( $SECURITY_CLASS, $USER, $GROUP );

sub set_user {
    my ( $class, $user ) = @_;
    return $USER = $user;
}

sub set_group {
    my ( $class, $group ) = @_;
    return $GROUP = $group;
}

sub set_security_class {
    my ( $class, $security_class ) = @_;
    return $SECURITY_CLASS = $security_class;
}


# You can change who the superuser is by modifying this ID

sub get_superuser_id             { return 1 }
sub get_supergroup_id            { return 1 }

sub global_security_object_class { return $SECURITY_CLASS }
sub global_user_current          { return $USER }
sub global_group_current         { return ( $GROUP ) ? [ $GROUP ] : [] }

1;
