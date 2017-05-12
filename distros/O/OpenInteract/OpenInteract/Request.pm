package OpenInteract::Request;

# $Id: Request.pm,v 1.16 2003/08/13 02:04:41 lachoy Exp $

use strict;
use base qw( Class::Singleton );
use Data::Dumper qw( Dumper );

$OpenInteract::Request::VERSION = sprintf("%d.%02d", q$Revision: 1.16 $ =~ /(\d+)\.(\d+)/);

$OpenInteract::Request::DEBUG = 0;


# This is only called the **first** time the object is created, which
# under mod_perl means when the first request comes into the httpd
# child; thereafter, Class::Singleton just returns the object. Be
# careful!

sub _new_instance {
    my ( $pkg, %p ) = @_;
    my $class = ref( $pkg ) || $pkg;
    my $self = bless( {}, $pkg );
    $self->initialize();
    return $self;
}


# Alias so people can do ->new() as well as ->instance()

sub new { my $class = shift; return $class->instance( @_ ); }


# Dummy method for subclasses to override

sub initialize { return 1; }


# Shortcuts pointing to the stash

sub cgi             { return $_[0]->get_stash( 'cgi' )    }
sub apache          { return $_[0]->get_stash( 'apache' ) }
sub cache           { return $_[0]->get_stash( 'cache' )  }
sub config          { return $_[0]->get_stash( 'config' ) }
sub CONFIG          { return $_[0]->get_stash( 'config' ) }
sub uri             { return $_[0]->get_stash( 'uri' )    }
sub error_handlers  { return $_[0]->get_stash( 'error_handlers' )  }


sub template_object {
    my ( $self ) = @_;
    my $tt_object = $self->get_stash( 'template_object' );
    return $tt_object if ( $tt_object );
    $tt_object = $self->template->initialize;
    $self->stash( 'template_object', $tt_object );
    return $tt_object;
}


sub db {
    my ( $self, $connect_key ) = @_;
    $connect_key ||= $self->CONFIG->{datasource}{default_connection_db} ||
                     $self->CONFIG->{default_connection_db};
    my $db = $self->get_stash( "db-$connect_key" );
    return $db if ( $db );
    require OpenInteract::DBI;
    $db = eval { OpenInteract::DBI->connect( $self->CONFIG->{db_info}{ $connect_key } ) };
    if ( $@ ) {
        OpenInteract::Error->set({ system_msg => $@,
                                   type       => 'db',
                                   extra      => $self->CONFIG->{db_info}{ $connect_key } });
        $self->scrib( 0, "Cannot connect to database! Immediately exiting process!" );
        my $error_msg = $self->throw({ code => 11 });
        die $error_msg;
    }
    return $self->db_stash( $db, $connect_key );
}


sub db_stash {
    my ( $self, $dbh, $connect_key ) = @_;
    $connect_key ||= $self->CONFIG->{datasource}{default_connection_db} ||
                     $self->CONFIG->{default_connection_db};
    return $self->stash( "db-$connect_key", $dbh );
}


sub ldap {
    my ( $self, $connect_key ) = @_;
    $connect_key ||= $self->CONFIG->{datasource}{default_connection_ldap} ||
                     $self->CONFIG->{default_connection_ldap};
    my $ldap = $self->get_stash( "ldap-$connect_key" );
    return $ldap if ( $ldap );
    require OpenInteract::LDAP;
    $ldap = eval { OpenInteract::LDAP->connect_and_bind(
                                                  $self->CONFIG->{ldap_info}{ $connect_key } ) };
    if ( $@ ) {
        OpenInteract::Error->set({ system_msg => $@,
                                   type       => 'db',
                                   extra      => $self->CONFIG->{db_info}{ $connect_key } });
        $self->scrib( 0, "Cannot connect to LDAP directory with connection ($connect_key)! Error: $@" );
        die $self->throw({ code => 11 });
    }
    return $self->ldap_stash( $ldap, $connect_key );

}


sub ldap_stash {
    my ( $self, $ldap, $connect_key ) = @_;
    $connect_key ||= $self->CONFIG->{datasource}{default_connection_ldap} ||
                     $self->CONFIG->{default_connection_ldap};
    return $self->stash( "ldap-$connect_key", $ldap );
}


# A shortcut, but we put the caller info in there so every error
# thrown doesn't appear to be coming from this location :)

sub throw {
    my ( $self, $p ) = @_; 
    ( $p->{package}, $p->{filename}, $p->{line} ) = caller;
    $p->{action} = $self->{current_context}{action};
    return $self->error->throw( $p );
}


# Put an object in the stash

sub stash {
    my ( $self, $name, $obj ) = @_;
    return {} unless ( ref $self );
    my $stash_class = $self->{stash_class};
    die "No stash class defined in OpenInteract::Request object!\n" unless ( $stash_class );
    return $stash_class->set_stash( $name, $obj );
}


# Get an object from the stash

sub get_stash {
    my ( $self, $item ) = @_;
    return {} unless ( ref $self );
    my $stash_class = $self->{stash_class};
    return $stash_class->get_stash( $item ) if ( $stash_class );
    return {};
}


# Alias stuff

my %ALIAS           = ();
my $ALIASES_SETUP   = 0;

sub ALIAS           { return \%ALIAS }
sub lookup_alias    { return $ALIAS{ $_[1] }{ $_[0]->{stash_class} } }


# read in all the aliases in %ALIAS and setup subroutines
# based on them -- we only need to do this once per child init,
# so increment a counter that says we've setup the aliases.
#
# Should we let people do this more than once? If we do, there will
# be a bunch of 'subroutine xxx redefined blah blah blah' messages...

sub setup_aliases {
    my ( $class ) = @_;
    return if ( $ALIASES_SETUP );
    $class->scrib( 1, "Aliases not yet setup. Setting up aliases for process ($$)" );
    no strict 'refs';
    foreach my $alias ( keys %ALIAS ) {
        *{ $class . '::' . $alias } = sub {
            my $self = shift; $self = $self->instance unless ( ref $self );
            return $ALIAS{ $alias }{ $self->{stash_class} }
        };
    }
    $ALIASES_SETUP++;
}


# I've finally relented and created a logging method. I'm still a
# little wary about the performance hit, but it's worth doing so that
# you don't have to restart mod_perl to get debugging info. All we
# need to do now is create a little admin gui so you can change the
# debug value in a session, which gets copied to all http children via
# a shared session
#
# Usage $R->DEBUG && $R->scrib( $level, $msg, $msg,... );
#   -- nothing done if $level < $CONFIG->{DEBUG}
#   -- all $msg get join'd with a ' ' character to form the message
#   -- msg sent to STDERR with "package::sub ($line) >> $msg"

sub scrib {
    my ( $self, $level, @msg ) = @_;
    return undef if ( $self->DEBUG < $level );
    my ( $pkg, $file, $line ) = caller;
    my @ci = caller(1);
    warn "$ci[3] ($line) >> ", join( ' ', @msg ), "\n";
}


# The last (?) piece to the debugging puzzle. You should now always
# call:
#
#   $R->DEBUG && $R->DEBUG && $R->scrib( 1, "xxx" );
#
# So that we don't have to do anything with the argument(s) to the
# scrib() method even if we're not debugging.

sub DEBUG {
    my ( $self ) = @_;
    my $app_debug = ( ref $self ) ? $self->CONFIG->{DEBUG} : 0;
    return $app_debug || $OpenInteract::Request::DEBUG;
}


# Do some stuff with the configuration -- set defaults, etc.
#
# We should probably move this to OpenInteract::Config
# Determine that the conductor is for a particular module

sub lookup_conductor {
    my ( $self, $action ) = @_;
    $action ||= shift @{ $self->{path}{current} };
    $self->scrib( 1, "Find conductor for action ($action)" );
    my ( $action_info, $action_method ) = $self->lookup_action( $action, { return => 'info' } );
    $self->scrib( 2, "Info for action:\n", Dumper( $action_info ) );
    my $conductor      = $action_info->{conductor};

    # skip conductor for component-only actions

    return undef  if ( $conductor eq 'null' ); 
    my $conductor_info = $self->CONFIG->{conductor}{ lc $conductor };
    my $method         = $conductor_info->{method};
    return ( $conductor_info->{class}, $method );
}


# Find the package/class corresponding to a particular 
# action tag
#
# Possible $opt options:
#   return => 'info' = return all action info
#   skip_default => bool = if there is no action under $action_name, don't substitute the default

sub lookup_action {
    my ( $self, $action_name, $opt ) = @_;
    $action_name ||= shift @{ $self->{path}{current} };
    my $action_list = ( ref $action_name eq 'ARRAY' ) ? $action_name : [ $action_name ];

    my $CONFIG = $self->CONFIG;
ACTION:
    foreach my $action ( @{ $action_list } ) {
        $self->scrib( 1, "Find action corresponding to ($action)" );
        my $action_info = ( $action ) ? $CONFIG->{action}{ lc $action }
                                      : $CONFIG->{action_info}{none};
        $self->scrib( 2, "Info for action:\n", Dumper( $action_info ) );

        # If we don't find a action, then we use the action from
        # 'not_found'; since we put this before the looping to find
        # 'action' references, this can simply be a pointer

        unless ( $opt->{skip_default} or $action_info ) {
            $action_info = $CONFIG->{action_info}{not_found};
            $self->scrib( 1, "Using 'notfound' action" );
        }

        # Allow as many redirects as we need

        while ( my $action_redir = $action_info->{redir} ) {
            $action_info = $CONFIG->{action}{ lc $action_redir };
            $self->scrib( 3, "Info within redir ($action_redir):\n", Dumper( $action_info ) );
        }
        next ACTION unless ( $action_info );
        $self->scrib( 1, "Found action info for ($action)" );
        $self->{current_context} = $action_info;
        return \%{ $action_info } if ( $opt->{return} eq 'info' );
        my $method = $action_info->{method};
        return ( $action_info->{class}, $action_info->{method} );
    }
    return undef;
}


# Clear out everything that shouldn't be around

sub finish_request {
    my ( $self ) = @_;

    # Ask the stash to clean itself up

    my $stash_class = $self->{stash_class};
    $stash_class->clean_stash;

    # Clear out all the content in the object

    foreach my $key ( keys %{ $self } ) {
        # warn "Cleaning up key '$key' from request...\n";
        delete $self->{ $key };
     }

}

1;

__END__

=head1 NAME

OpenInteract::Request -- container for request info and output

=head1 SYNOPSIS

 # Anywhere in your website

 my $R = OpenInteract::Request->instance;
 my $user_rec = $R->user->fetch( $user_id );
 my $org_recs = $R->org->fetch_group;

 my $db_info = $R->CONFIG->db_info();
 my $dbh  = $R->db;

=head1 DESCRIPTION

The Request object is fairly simple, having only a few methods to
it. But it really ties applications together in the OpenInteract
framework, acting as an object repository, a layer between your object
names and their classes, and as a data store between different parts
of the process. Since it is 'always around' (more later), you can thus
have necessary configuration information, your database handle, cache
store, template parser or other tools at your fingertips.

This package is designed to run under mod_perl. Since it is a subclass
of L<Class::Singleton>, it maintains the request object (usually $R)
around for the life of the Apache child. The intended side effect of
this allows you to pluck the object from the ether from any handler or
utility you are running by simply doing:

 my $R = OpenInteract::Request->intance;

That is it. You do not need a 'use OpenInteract::Request;' statement,
you do not need to pass the object around from method to method.

The other job of the OpenInteract::Request object is to keep track of
where we are: which action we are using, what URL was originally
requested. etc.

=head2 PACKAGE LEXICALS

B<%OBJECTS>

Hash holding all the general objects needed throughout
this request. Note that finish_request() cleans these
up (except for the database handle and config object)
at the end of every request.

B<%ALIAS>

Holds mapping of alias to class name. When the website 
is first started, you should call:

 OpenInteract::Request->setup_aliases();

Which turns these hash entries into subroutines so you can use the
inline method -- $R-E<gt>user vs $R-E<gt>user(). The latter one is
necessary if you do everything strictly via AUTOLOAD. (Been there,
done that...)

=head1 METHODS

B<instance()>

Returns: a I<bless>ed I<Request> object. (Inherited from
C<Class::Singleton>.)

B<initialize()>

Initialize the request. You can override this however you wish.

B<throw( \%params )>

Make it easy to throw errors from anywhere in the system. All
information gets passed directly to C<OpenInteract::Error>, although
we set the package, filename and line information so it does not
appear to the error handler that all errors are mysteriously being
thrown from OpenInteract::Request, and all from one line, too... :)

Note that you do not even need to instantiate an object for this:

 OpenInteract::Request->instance->throw( { ... } );

See also documentation in L<OpenInteract::Error> and the
L<OpenInteract::ErrorObject>, particularly for the parameter names.

B<stash( 'name', $obj )>

Adds an object indexed by 'name' to our stash class. If the object
already exists in the stash class, the default behavior is to simply
overwrite. (You can write a more complicated stash class if you
like...)

Examples:

 $R->stash( 'db', $db );
 $R->stash( 'apache', $apr );

B<get_stash( 'name' )>

Retrieves the value corresponding to 'name' from the current stash
class. Note that many aliases (e.g., "$R-E<gt>db") actually call
'get_stash' internally, so you will not see this used very frequently.

B<db_stash( $handle, [ $connection_key ] )>

B<ldap_stash( $handle, [ $connection_key ] )>

B<setup_aliases()>

Creates subroutines in the symbol table for this class 
matching up to the entries in the lexical %ALIAS. You should
call this when your website first starts.

B<lookup_alias( $alias )>

Returns a class name matching up to $alias. Use this when you do not
know the alias beforehand. You can use it in two different ways:

 1)  $R->$alias()->fetch( $id );

 2)  my $class = $R->lookup_alias( $alias );
     my $obj = $class->fetch( $id );

B<scrib( $level, $msg [, $msg, $msg, ... ] )>

Centralized notification logging. Check the {DEBUG} key in the config
object, which is stored in the stash class, for the current debugging
level. If that level is less than the level passed in, we do
nothing. But if the value is equal to or greater than the level passed
in then we 'warn' with the error.

A common idiom is:

  $R->DEBUG && $R->DEBUG && $R->scrib( 1, "Result:", $myobj->result() );

This first checks to see if debugging is on, and if so only then calls
the (more expensive) scrib() method. As seen below, C<DEBUG()> checks
the application debugging level (generally from the server
configuration), so this might send debugging info for one website but
not another.

Note that you can pass multiple messages at once to the method -- the
method C<join>s them with a single space between the messages.

None of the $msg items need to conetain the filename, package name,
subroutine name or line number -- we pull all that from the reference
material sent via L<caller>.

You can use this as a class method as well:

 OpenInteract::Request->instance->scrib( 2, "Boring log message" );

And you can use either the object or class methods even if you have
not created and registered a config object. If you have not done so,
we will use the value of the package variable $DEBUG in this class.

This means that setting the value of the package variable $DEBUG will
send B<all> messages from B<any> application at that level or lower to
'warn'. Be careful or you will get some big honking logfiles! You
might want to use C<local> for setting this value if you really need
to.

Finally, any log messages sent with a debug level of '0' will always
go to the log, as long as you do not check the result of C<DEBUG()>
first.. (We have not accounted for any weisenheimers setting the
config/class debug level to a negative number, but who would do such a
thing?)

B<DEBUG()>

Class or object method to return the current debugging level. If this
is called from an object, we query the configuration hashref in the
stash class for the debugging level and return it. If that is not set,
we also check the class variable 'DEBUG' and send its value. Most of
the time you will not want to set this because you will get enormous
logfiles. But hey, if that is what you want...

B<lookup_conductor( [ $action ] )>

Finds the conductor for a particular action.

Returns a two-element list: class and method.

If $action is not passed in, we find the name from
$R-E<gt>{path}-E<gt>{current}.

B<lookup_action( [ $action, \%params ] )>

Finds information associated with a particular action from the
configuration.

If $action is not passed in, we find the name from
$R-E<gt>{path}-E<gt>{current}.

You have the option of refusing to allow the method to return a
default action if yours is not found. We use this to implement
'static' web pages. For instance, if there is no action corresponding
to the path '/mod_perl/guide/toc', then we find the default action
(which handles page objects) and return its information.

Returns either a two-element list (class and method) or with a
'return' parameter value of 'info', returns a hashref with all known
information about the action.

Parameters:

=over 4

=item *

return ($)

'info' means return all information about the action

=item *

skip_default (bool)

Any true value means to *not* use the default action name, even if the
action name is not found.

=back

B<finish_request()>

Cleans out this object and tells the stash class associated with the
request to do the same.

=head1 TO DO

Nothing known.

=head1 BUGS

none known.

=head1 COPYRIGHT

Copyright (c) 2001-2002 intes.net, inc.. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters <chris@cwinters.com>

Christian Lemburg <lemburg@aixonix.de> bugged me about getting a
logging method (scrib) in here.
