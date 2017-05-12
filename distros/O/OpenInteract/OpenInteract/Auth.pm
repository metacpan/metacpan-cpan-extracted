package OpenInteract::Auth;

# $Id: Auth.pm,v 1.18 2002/06/04 11:29:54 lachoy Exp $

use strict;
use Data::Dumper qw( Dumper );

$OpenInteract::Auth::VERSION = sprintf("%d.%02d", q$Revision: 1.18 $ =~ /(\d+)\.(\d+)/);


# Authenticate a user -- after calling this method if
# $R->{auth}{logged_in} is true then $R->{auth}{user} will be a
# user object.

sub user {
    my ( $class ) = @_;
    my $R = OpenInteract::Request->instance;

    my ( $uid );

    # Check to see if the user is in the session

    my $user_refresh = $R->CONFIG->{session_info}{cache_user};
    if ( $user_refresh > 0 ) {
        if ( my $user = $R->{session}{_oi_cache}{user} ) {
            if ( time < $R->{session}{_oi_cache}{user_refresh_on} ) {
                $R->DEBUG && $R->scrib( 1, "Got user from session ok" );
                $R->{auth}{user} = $user;
                $R->{auth}{logged_in} = 1;
                return;
            }

            # If we need to refresh the user object, pull the $uid out
            # so we know what to refresh...
            $R->DEBUG && $R->scrib( 1, "User session cache expired; refreshing from db" );
            $uid = $user->id;
        }
    }

    $uid ||= $class->fetch_user_id;
    if ( $uid ) {
        $R->DEBUG && $R->scrib( 1, "Found uid [$uid]; fetching user" );

        $R->{auth}{user} = eval { $class->fetch_user( $uid ) };

        # If there's a failure fetching the user, we need to ensure that
        # this user_id is not passed back to us again so we don't keep
        # going through this process...

        if ( $@ or ! $R->{auth}{user} ) {
            return $class->fetch_user_failed( $uid );
        }

        $R->DEBUG && $R->scrib( 1, "User found [$R->{auth}{user}{login_name}]" );
        $R->{auth}{logged_in} = 1;

        $class->check_first_login;
        if ( $user_refresh > 0 ) {
            $class->set_cached_user;
        }
        return;
    }
    $R->DEBUG && $R->scrib( 1, "No uid found in session. Finding login info." );

    # If no user info found, check to see if the user logged in

    $class->login_user;

    # If not, create an 'empty' user and we're done

    unless ( $R->{auth}{user} ) {
        $R->DEBUG && $R->scrib( 1, "Creating the not-logged-in user." );
        $class->create_nologin_user;
        return;
    }

    $R->{auth}{logged_in} = 1;
    $class->remember_login;
    return;
}

# Just grab the user_id from somewhere

sub fetch_user_id {
    my ( $class ) = @_;
    my $R = OpenInteract::Request->instance;
    return $R->{session}{user_id};
}


# Use the user_id to create a user (don't use eval {} around the
# fetch(), this should die if it fails)

sub fetch_user {
    my ( $class, $uid ) = @_;
    my $R = OpenInteract::Request->instance;
    return $R->user->fetch( $uid, { skip_security => 1 } );
}


# What to do if the user fetch fails

sub fetch_user_failed {
    my ( $class, $uid ) = @_;
    my $R = OpenInteract::Request->instance;
    OpenInteract::Error->set( SPOPS::Error->get );
    $R->throw({ code => 311 });
    $R->{session}{user_id} = undef;
    return;
}


# If there's a removal date, then this is the user's first login

# TODO: Check if this is working, if it's needed, ...

sub check_first_login {
    my ( $class ) = @_;
    my $R = OpenInteract::Request->instance;
    if ( $R->{auth}{user}{removal_date} ) {
        $R->DEBUG && $R->scrib( 1, "First login for user! Do some cleanup." );
        $R->{auth}{user}{removal_date} = undef;

        # blank out the removal date -- note that this doesn't seem to
        # work properly, and put the user in the public group

        eval {
            $R->{auth}{user}->save;
            $R->{auth}{user}->make_public;
        };

        # need to check for save/security errors here
    }
}


# If no user found elsewhere, see if a login_name and password were
# passed in; if so, try and login the user and track the info

sub login_user {
    my ( $class ) = @_;
    my $R = OpenInteract::Request->instance;
    my $CONFIG = $R->CONFIG;

    my $login_field    = $CONFIG->{login}{login_field};
    my $password_field = $CONFIG->{login}{password_field};
    unless ( $login_field and $password_field ) {
        $R->throw({ code => 205, type => 'system' });
        return;
    }

    my $login_name = $R->apache->param( $login_field );
    return undef unless ( $login_name );
    $R->DEBUG && $R->scrib( 1, "Found login name from form: ($login_name)" );

    my $user = eval { $R->user->fetch_by_login_name( $login_name,
                                                     { return_single => 1,
                                                       skip_security => 1 } ) };
    if ( $@ ) {
      my $ei = SPOPS::Error->get;
      $R->scrib( 0, "Error when fetching by login name: $ei->{system_msg}\n" );
    }
    unless ( $user ) {
        $R->scrib( 0, "User with login ($login_name) not found. Throwing auth error" );
        $R->throw({ code  => 401,
                    type  => 'authenticate',
                    extra => { login_name => $login_name } });
        return;
    }

    # Check the password

    my $password   = $R->apache->param( $password_field );
    $R->DEBUG && $R->scrib( 5, "Password entered: ($password)" );
    unless ( $user->check_password( $password ) ) {
        $R->scrib( 0, "Password check for ($login_name) failed. Throwing auth error" );
        $R->throw({ code  => 402,
                    type  => 'authenticate',
                    extra => { login_name => $login_name } });
        return;
    }
    $R->DEBUG && $R->scrib( 1, "Passwords matched; UID ($user->{user_id})" );

    # Persist the user ID via the session (whether the session is
    # transient is handled in 'remember_login()')

    $R->{session}{user_id} = $user->id;
    $R->{auth}{user} = $user;
    $class->set_cached_user;

    return $R->{auth}{user};
}


sub set_cached_user {
    my ( $class ) = @_;
    my $R = OpenInteract::Request->instance;
    my $user_refresh = $R->CONFIG->{session_info}{cache_user};
    return unless ( $user_refresh > 0 );
    $R->{session}{_oi_cache}{user} = $R->{auth}{user};
    $R->{session}{_oi_cache}{user_refresh_on} = time + ( $user_refresh * 60 );
    $R->DEBUG && $R->scrib( 1, "Set user to session cache, expires ",
                               "in [$user_refresh] minutes" );
}


# If we created a user, make the expiration transient unless told otherwise.

sub remember_login {
    my ( $class ) = @_;
    my $R = OpenInteract::Request->instance;
    return unless ( $R->{auth}{user} );
    return if ( $R->CONFIG->{login}{always_remember} );

    my $remember_field = $R->CONFIG->{login}{remember_field};
    if ( ! $remember_field or ! $R->apache->param( $remember_field )  ) {
        $R->{session}{expiration} = undef;
    }
}

# Create a 'dummy' user

sub create_nologin_user {
    my ( $class ) = @_;
    my $R = OpenInteract::Request->instance;
    $R->{auth}{logged_in} = 0;
    delete $R->{session}{user_id};
    return $R->{auth}{user} = $R->user->new({ login_name => 'anonymous',
                                              first_name => 'Anonymous',
                                              last_name  => 'User',
                                              user_id    => 99999 });
}


# If the user is logged in, retrieve the groups he/she/it belongs to

sub group {
    my ( $class ) = @_;
    my $R = OpenInteract::Request->instance;
    unless ( $R->{auth}{logged_in} ) {
        $R->DEBUG && $R->scrib( 1, "No logged-in user found, not retrieving groups." );
        return;
    }
    $R->DEBUG && $R->scrib( 1, "Authenticated user exists; getting groups." );

    # Check to see if the group is in the session
    my $group_refresh = $R->CONFIG->{session_info}{cache_group};
    if ( $group_refresh > 0 ) {
        if ( my $groups = $R->{session}{_oi_cache}{group} ) {
            if ( time < $R->{session}{_oi_cache}{group_refresh_on} ) {
                $R->DEBUG && $R->scrib( 1, "Got groups from session ok" );
                $R->{auth}{group} = $groups;
                return;
            }
            $R->DEBUG && $R->scrib( 1, "Group session cache expired; refreshing from db" );
        }
    }

    $R->{auth}{group} = eval { $R->{auth}{user}->group };
    if ( $@ ) {
        OpenInteract::Error->set( SPOPS::Error->get );
        $R->throw({ code => 309 });
    }
    else {
        if ( $group_refresh > 0 ) {
            $R->{session}{_oi_cache}{group} = $R->{auth}{group};
            $R->{session}{_oi_cache}{group_refresh_on} = time + ( $group_refresh * 60 );
            $R->DEBUG && $R->scrib( 1, "Set groups to session cache, expires ",
                                       "in [$group_refresh] minutes" );
        }
        $R->DEBUG && $R->scrib( 2, "Retrieved groups: ",
                                   join( ', ', map { "($_->{name})" } @{ $R->{auth}{group} } ) );
    }
}


sub is_admin {
    my ( $class ) = @_;
    my $R = OpenInteract::Request->instance;

    return unless ( $R->{auth}{logged_in} );
    return unless ( ref $R->{auth}{group} eq 'ARRAY' );

    my $CONFIG = $R->CONFIG;

    if ( $R->{auth}{user}->id eq $CONFIG->{default_objects}{superuser} ) {
        return $R->{auth}{is_admin}++;
    }

    my $site_admin_id = $CONFIG->{default_objects}{site_admin_group};
    my $supergroup_id = $CONFIG->{default_objects}{supergroup};
    foreach my $group ( @{ $R->{auth}{group} } ) {
        my $group_id = $group->id;
        if ( $group_id eq $site_admin_id or $group_id eq $supergroup_id ) {
            return $R->{auth}{is_admin}++ ;
        }
    }
}


########################################
# CUSTOM AUTH METHOD

sub custom_handler {
    my ( $class ) = @_;
    my $R = OpenInteract::Request->instance;
    my $CONFIG = $R->CONFIG;
    my $custom_class = $CONFIG->{login}{custom_handler};
    return unless ( $custom_class );

    eval "require $custom_class";
    if ( $@ ) {
        $R->scrib( 0, "Tried to use custom login handler [$custom_class]",
                   "but requiring the class failed: $@" );
        return;
    }
    my $custom_method = $CONFIG->{login}{custom_method}
                        || 'handler';
    $R->scrib( 1, "Custom login handler/method being used: ",
               "[$custom_class] [$custom_method]" );
    eval { $custom_class->$custom_method() };
    if ( $@ ) {
        $R->scrib( 0, "Custom login handler died with: $@" );
        $class->custom_handler_failed;
    }
}

sub custom_handler_failed {
    my ( $class ) = @_;
    my $R = OpenInteract::Request->instance;
    my $CONFIG = $R->CONFIG;
    my $custom_class = $CONFIG->{login}{custom_handler};
    my $fail_method  = $CONFIG->{login}{custom_fail_method};
    return unless ( $fail_method );
    eval { $custom_class->$fail_method() };
    if ( $@ ) {
        $R->scrib( 0, "Caught error from failure method [$custom_class]",
                   "[$fail_method]: $@" );
    }
}


1;

__END__

=pod

=head1 NAME

OpenInteract::Auth - Authenticate the user object and create its groups

=head1 SYNOPSIS

 # Authenticate the user based on the session information
 # or the login information

 OpenInteract::Auth->user;

 # Fetch the groups for the logged-in user

 OpenInteract::Auth->group;

 # See whether this user is an administrator

 OpenInteract::Auth->is_admin;

 # Run custom methods as defined in the server configuration

 OpenInteract::Auth->custom_handler;

=head1 DESCRIPTION

This class/interface is responsible for authenticating users to the
system and other authentication checks. If you have custom
authentication needs you can specify your class in the server
configuration and create your own or subclass this class and use
pieces of it as needed.

This class tries to create a user in one of two ways:

=over 4

=item 1.

Find the user_id in their session information and create a user object
from it.

=item 2.

Find the $LOGIN_FIELD and $PASSWORD_FIELD arguments passed in via
GET/POST and try to create a user with that login name and check the
password.

=back

If either of these is successful, then we create a user object and put
it into:

 $R->{auth}{user}

where it can be retrieved by all other handlers, modules,
etc. Otherwise we create a 'transient' (not serialized) user object
for every request via the C<create_nologin_user()> method, which you
can override by subclassing this class.

The class also creates an arrayref of groups the user belongs to as
long as the user is a valid one.

=head1 METHODS

Neither of these methods returns a value that reflects what they
did. Their success is judged by whether $R has entries for the user
and groups.

B<user()>

Creates a user object by whatever means possible and puts it into:

 $R->{auth}{user}

Note that we also set:

 $R->{auth}{logged_in}

which should be used to see whether the user is logged in or not. We
will be changing the interface slightly so that you can no longer just
check to see if $R-E<gt>{auth}-E<gt>{user} is defined. It will be
defined with the 'not-logged-in' user to prevent some a nasty bug from
happening.

In this method we check to see whether the user has typed in a new
username and password. By default, the method will check in the
variables 'login_login_name' for the username and 'login_password' for
the password. (Both are stored as constants in this module.)

However, you can define your own variable names in your
C<conf/server.perl> file. Just set:

   login => { login_name => 'xxx',
              password   => 'xxx', ... },

(If you modify the template for logging in to have new names under the
'INPUT' variables you will want to change these.)

You can also define custom behavior for a login by specifying in the
server configuration:

   login => { custom_handler => 'My::Handler::Login' },

The C<handler()> method will then be called on 'My::Handler::Login'
after the users and groups have been fetched when the method
C<custom_handler()> is called on this class or a subclass.

B<group()>

If a user object has been created, this fetches the groups the user
object belongs to and puts the arrayref of groups into:

 $R->{auth}{group}

B<is_admin()>

Looks at the user and groups and determines whether the user is an
administrator. If the user is an administrator, then:

 $R->{auth}{is_admin}

is set to a true value.

B<custom_handler()>

Runs the handler defined in the server configuration key
'login.custom_handler' using the method 'login.custom_method' or
'handler', if that is not defined.

If the custom handler fails, we will call 'login.custom_fail_method'
on the same class if the key is defined.

=head1 SUBCLASSING

As of OpenInteract 1.35, this module is now more amenable to
subclassing. Both the C<user()> and C<group()> methods are broken down
into more discrete actions which you can override as you need.

=head2 User Fetching Actions

B<fetch_user_id()>

Retrieves the user ID for this request.

Default: get the 'user_id' key from the session.

Returns: user ID value.

B<fetch_user( $user_id )>

Called only if a user ID is found using C<fetch_user_id()>. This
method retrieves the user object corresponding to C<$user_id>.

Note that if you are using SPOPS for this (recommended), you almost
certainly want to pass a true value for the 'skip_security' parameter,
such as:

    return $R->user->fetch( $uid, { skip_security => 1 } );

Because otherwise the superuser will never be able to login

Default: get the SPOPS user object matching C<$user_id>.

Returns: user object on success, undef if user object not found, a
C<die> on failure.

B<fetch_user_failed( $user_id )>

Called only if C<fetch_user()> throws a C<die>.

Default: Throws a code '311' error, blanks out the 'user_id' key of
the session and returns undef.

Returns: not checked

B<check_first_login()>

Called if C<fetch_user()> succeeds. Many times you want to execute
certain actions when the user logs in for the first time. This is a
hook for you to do so.

Default: Make the user part of the 'public' group (this should
probably done elsewhere)

Returns: not checked

B<login_user()>

Called if C<fetch_user_id()> does not find a user ID. This should look
at the form values passed in and find at least a login name and
password. If values for these are not found, the function returns undef.

If these values are found, the function should fetch the user and
authenticate the user by whatever means are appropriate. If the user
is properly authenticated, the function should set whatever values are
necessary to ensure the user can be found by C<fetch_user_id()> -- by
default, this means setting 'user_id' in the session, but your
application might use a different means to track the user.

Default: Look at the 'login_field' and 'password_field' as set in the
server configuration under 'login' for the username and password.

Returns: A user object, along with setting the user object to
C<{auth}{user}> in the L<OpenInteract::Request|OpenInteract::Request>
object. If you cannot create one, just return undef.

B<remember_login()>

Default is to make sessions (along with user identification) transient
-- once the browser that created the session is closed, the cookie
expires. The user can choose to have the system and their browser
remember the session for a longer period of time (specified in the
server config key 'session'->'expiration').

This method makes the session non-transient if either the user checks
off the 'remember_field' checkbox (the fieldname is specified in the
server config key 'login'->'remember_field') or if the server config
setting for 'login'->'always_remember' is true.

B<custom_login_failed()>

Executed if the execution of the custom login handler fails. (The
custom login handler is specified by the class and method defined in
the server configuration under 'login', 'custom_login_handler' and
'custom_login_method'.)

Default: Run C<create_nologin_user()>.

Returns: not checked

B<create_nologin_user()>

If a user is not logged in, we create transient user object so that
all OpenInteract handlers have something they can refer to. It is not
a valid user and it gets created anew with every request where the
user is not logged in.

If you want to rename the login_name, first/last name, etc, just
subclass this class, create your own method, then specify your class
in the server configuration under 'auth'.

This method should ensure that the system knows a user is not logged
in by setting:

 $R->{auth}{logged_in} = undef;

and by blanking out any tracking information your application sets in
the session.

Finally, the method should set:

 $R->{auth}{user}

To the transient user object you have created.

=head2 Group Fetching Actions

None! The C<group()> method is so simple that we thought breaking it
into pieces would make it overly complex. If you override it, your
code should look something like:

 if ( $R->{auth}{logged_in} ) {
    $R->{auth}{group} = $R->{auth}{user}->group;
 }

Which is basically all this method does, with some error checking and
debugging thrown in.

=head1 TO DO

B<Ticket handling>

We should put checks in here to allow an application to check
for expired authentication tickets, or to allow a module to add an
authentication handler as a callback which implements its own logic
for this.

=head1 BUGS

None known.

=head1 SEE ALSO

L<OpenInteract::User|OpenInteract::User>

L<OpenInteract::Group|OpenInteract::Group>

=head1 COPYRIGHT

Copyright (c) 2001-2002 intes.net, inc.. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters <chris@cwinters.com>

=cut
