package OpenInteract::Handler::GenericDispatcher;

# $Id: GenericDispatcher.pm,v 1.92 2002/11/10 16:33:39 lachoy Exp $

use strict;
use base qw( Exporter );
use SPOPS::Secure qw( SEC_LEVEL_WRITE );

use constant DEFAULT_SECURITY_KEY => 'DEFAULT';

my $CLASS_TRACKING_KEY = 'class_cache_track';

$OpenInteract::Handler::GenericDispatcher::VERSION = sprintf("%d.%02d", q$Revision: 1.92 $ =~ /(\d+)\.(\d+)/);
@OpenInteract::Handler::GenericDispatcher::EXPORT_OK = qw( DEFAULT_SECURITY_KEY );


# Note that we do "no strict 'refs'" a few times in various methods
# throughout this packge -- it's just so we can refer to packge
# variables properly.

sub handler {
    my ( $class, $p ) = @_;
    my $R = OpenInteract::Request->instance;

    # This routine should take care of parsing the task from the
    # information passed in the $p hashref or via theURL and if not
    # given, discerning a default; if there is no task returned, we're
    # outta here.

    $p->{TASK} ||= $class->_get_task;

    $R->DEBUG && $R->scrib( 1, "Trying to run [$class] with [$p->{TASK}]" );

    # Default is to email the author there is no default task defined.

    return $class->_no_task_found  unless( $p->{TASK} );

    # If we are not allowed to run the task, the error handler should
    # die() with the content for the page

    unless ( $class->_task_allowed( $p->{TASK} ) ) {
        $R->DEBUG && $R->scrib( 1, "[$p->{TASK}] is forbidden by [$class]; bailing." );
        $R->throw({ code  => 303,
                    type  => 'module',
                    extra => { task => $p->{TASK} } });
    }

    # Check to see that user can do this task with security; if not
    # routine should die() with an error message.

    $p->{level} = $class->_check_task_security( $p->{TASK} );

    # For subclasses to override -- this would be useful if you want to
    # create a new dispatcher by subclassing this class and, for
    # instance, do a lookup in a hash or database as to what 'tab'
    # should be selected in a menubar on your web page.

    $class->_local_action( $p );
    my $task = $p->{TASK};
    return $class->$task( $p );
}


########################################
# ACTIONS/TASKS

sub _local_action { return; }


# Get the task asked to do use the 'default_method' package variable

sub _get_task {
    my ( $class ) = @_;
    no strict 'refs';
    my $R = OpenInteract::Request->instance;
    my $task = lc shift @{ $R->{path}{current} } ||
               ${ $class . '::default_method' };
    return $task;
}


# If there is no task defined, use the default method that $class
# has specified. What to do if $class hasn't specified one? 
# We should probably bail, create an error object and send it
# to the module's author. (cool!)

sub _no_task_found {
    my ( $class ) = @_;
    my $author_msg = <<MSG;
Your module ($class) does not have a default task defined.
Please create the package variable '\$$class\:\:default_method'
as soon as possible.

Thanks!

The Management
MSG
    no strict 'refs';
    my $R = OpenInteract::Request->instance;
    return $R->throw( { code       => 304,
                        type       => 'module',
                        system_msg => "Author has not defined default task for $class",
                        extra => { email   => ${ $class . '::author' },
                                   subject => "No default task defined for $class",
                                   msg     => $author_msg } } );
}

sub _task_allowed {
    my ( $class, $task ) = @_;

    # Tasks beginning with '_' are not allowed by default

    return undef if ( $task =~ /^_/ );
    no strict 'refs';

    # Check to see if this task is forbidden from being publicly called; if so, bail.

    my %forbidden = map { $_ => 1 } @{ $class . '::forbidden_methods' };
    return ! $forbidden{ $task };
}


sub _check_task_security {
    my ( $class, $task ) = @_;
    no strict 'refs';
    my $R = OpenInteract::Request->instance;

    # If the class uses security, $level will be overridden; if 
    # it does not use security, then it will be ignored. Note that
    # we pass this on to the handler so it doesn't need to check the
    # security again.

    my $level = SEC_LEVEL_WRITE;

    # Allow the handler to perform a shortcut if it wants to check
    # security; note that if security for a task is not defined in the
    # package, this check assumes WRITE security as a default

    if ( $class->isa( 'SPOPS::Secure' ) ) {
        $level           = eval { $R->user->check_security({class     => $class,
                                                            object_id => '0' }) };
        my %all_levels   = %{ $class . '::security' };
        my $target_level = $all_levels{ $task } ||
                           $all_levels{ DEFAULT_SECURITY_KEY() } ||
                           SEC_LEVEL_WRITE;
        $R->DEBUG && $R->scrib( 2, "Security after check for ($task):\n",
                                   "user has: $level; user needs: $target_level" );

        # Security check failed, so bail (error handler die()s with an error message

        if ( $level < $target_level ) {
            $R->throw( { code => 305, type => 'security',
                         extra => { user_level     => $level,
                                    required_level => $target_level,
                                    class          => $class,
                                    task           => $task } } );
        }
    }
    return $level;
}



########################################
# CACHING

sub check_cache {
    my ( $class, $p, $key_params ) = @_;
    my $R = OpenInteract::Request->instance;
    my $cache = $R->cache;
    if ( $R->{auth}{is_admin} || $p->{skip_cache} || ! $cache ) {
        return undef;
    }

    my $key = $class->_make_cache_key( $p, $key_params );
    return undef unless ( $key );
    my $data = $cache->get({ key => $key });
    $R->DEBUG && $R->scrib( 1, "CACHE HIT! [Task: $p->{TASK}]" ) if ( $data );
    return $data;
}


sub _make_cache_key {
    my ( $class, $p, $key_params ) = @_;
    return undef unless ( ref $p->{ACTION}{cache_key} eq 'HASH' );
    return undef unless ( $p->{ACTION}{cache_key}{ $p->{TASK} } );
    return join( '||', $p->{ACTION}{cache_key}{ $p->{TASK} },
                       map { join( '=', $_, $key_params->{ $_ } ) }
                             sort keys %{ $key_params } );
}


sub generate_content {
    my ( $class, @params ) = @_;
    my ( $p, $key_params, $template_params, $variables, $template_source );
    my $num_params = scalar @params;
    if ( $num_params == 4 ) {
        ( $p, $key_params, $variables, $template_source ) = @params;
        $template_params = {};
    }
    elsif ( $num_params == 5 ) {
        ( $p, $key_params, $template_params, $variables, $template_source ) = @params;
    }
    else {
        die "Incorrect parameters passed to generate_content. ",
            "(Need 4 or 5; given $num_params)\n";
    }
    my $R = OpenInteract::Request->instance;
    my $content = $R->template->handler( $template_params, $variables, $template_source );
    my $cache = $R->cache;
    if ( $R->{auth}{is_admin} || $p->{skip_cache} || ! $cache ) {
        return $content;
    }

    my $key = $class->_make_cache_key( $p, $key_params );
    if ( $key ) {
        my $cache_expire = $p->{ACTION}{cache_expire} || {};
        $cache->set({ key    => $key,
                      data   => $content,
                      expire => $cache_expire->{ $p->{TASK} } });
        my $tracking = $cache->get({ key => $CLASS_TRACKING_KEY }) || {};
        push @{ $tracking->{ $class } }, $key;
        $R->DEBUG && $R->scrib( 1, "Adding key [$key] to class [$class]" );
        $cache->set({ key  => $CLASS_TRACKING_KEY,
                      data => $tracking });
    }
    return $content;
}


sub clear_cache {
    my ( $class ) = @_;
    my $R = OpenInteract::Request->instance;
    my $cache = $R->cache;
    return unless ( $cache );

    $R->scrib( 0, "Trying to clear cache for items in class [$class]" );
    my $tracking = $cache->get({ key => $CLASS_TRACKING_KEY });
    unless ( ref $tracking eq 'HASH' and scalar keys %{ $tracking } ) {
        $R->scrib( 0, "Nothing has yet been tracked, nothing to clear" );
        return;
    }
    my $keys = $tracking->{ $class } || [];
    foreach my $cache_key ( @{ $keys } ) {
        $R->scrib( 0, "Clearing key [$cache_key]" );
        $cache->clear({ key => $cache_key });
    }
    $tracking->{ $class } = [];
    $cache->set({ key => $CLASS_TRACKING_KEY, data => $tracking });
    $R->scrib( 0, "Tracking data saved back" );
}


########################################
# UTILITIES

# Return an object if we are able to construct it from parameters or
# wherever; if we have errors, raise them 

sub _create_object {
    my ( $class, $p ) = @_;
    my $R = OpenInteract::Request->instance;
    my $id_field_list = ( ref $p->{_id_field} )
                          ? $p->{_id_field} : [ $p->{_id_field} ];
    my $object_class = $p->{_class};
    unless ( scalar @{ $id_field_list } and $object_class ) {
        die "Cannot retrieve object without id_field and class definitions\n";
    }

    my $oid = undef;
    foreach my $id_field ( @{ $id_field_list } ) {
        $oid = $R->apache->param( $id_field );
        last if ( $oid );
    }
    return undef unless ( $oid );
    my $object = eval { $object_class->fetch( $oid ) };
    if ( $@ ) {
        my $ei = OpenInteract::Error->set( SPOPS::Error->get );
        my $error_msg = undef;
        if ( $ei->{type} eq 'security' ) {
            $error_msg = "Permission denied: you do not have access to " .
                         "view the requested object.";
        }
        else {
            $R->throw( { code => 404 } );
            $error_msg = "Error encountered trying to retrieve object. " .
                         "The error has been logged."
        }
        die "$error_msg\n";
    }
    return $object;
}

sub date_process {
    my ( $class, $date ) = @_;
    return {} if ( ! $date );
    my ( $y, $m, $d ) = split /\D/, $date;
    $m =~ s/^0//;   # do this so comparisons
    $d =~ s/^0//;   # within Template work
    return { year => $y, month => $m, day => $d };
}

sub date_read {
    my ( $class, $prefix, $defaults ) = @_;
    $defaults ||= {};
    my $apr = OpenInteract::Request->instance->apache;
    my $day   = $apr->param( "${prefix}_day" )   || $defaults->{day_default};
    my $month = $apr->param( "${prefix}_month" ) || $defaults->{month_default};
    my $year  = $apr->param( "${prefix}_year" )  || $defaults->{year_default};
    return join '-', $year, $month, $day if ( $day and $month and $year );
    return undef;
}

1;

__END__

=head1 NAME

OpenInteract::Handler::GenericDispatcher - Define task-dispatching, security-checking and other routines for Handlers to use

=head1 SYNOPSIS

 use OpenInteract::Handler::GenericDispatcher qw( DEFAULT_SECURITY_KEY );
 use SPOPS::Secure qw( :level );

 @OpenInteract::Handler::MyHandler::ISA = qw(
                             OpenInteract::Handler::GenericDispatcher SPOPS::Secure );
 %OpenInteract::Handler::MyHandler::default_security = (
     DEFAULT_SECURITY_KEY() => SEC_LEVEL_READ,
     'edit'                 => SEC_LEVEL_WRITE );

=head1 DESCRIPTION

The Generic Dispatcher provides the methods to discern what task is
supposed to execute, ensure that the current user is allowed to
execute it, and returns the results of the task.

It is meant to be subclassed so that your handlers do not have to keep
parsing the URL for the action to take. Each action the Generic
Dispatcher takes can be overridden with your own.

This module provides the routine 'handler' for you, which does all the
routines (security checking and other) for you, then calls the proper
method.

There are also a couple of utility methods you can use, although they
will probably be punted off to a separate module at some point.

B<NOTE>: This module will likely be scrapped for a more robust
dispatching system. Please see L<NOTES> for a discussion.

=head1 METHODS

Even though there is only one primary method for this class
(C<handler()>), you may override individual aspects of the checking
routine:

B<_get_task>

Return a task name by whatever means necessary. Default behavior is
to return the next element (lowercased) from:

 $R->{path}{current}

If that element is undefined (or blank), the default behavior returns
the the package variable B<default_method>.

Return a string corresponding to a method.

B<_no_task_found>

Called when no task is found from the I<_get_task> method. Default
behavior is to email the author of the handler (found in the package
variable B<author>) and tell him/her to at least define a default
method.

Method should either return or I<die()> with html necessary for
displaying an error.

B<_task_allowed( $task )>

Called to ensure the $task found earlier is not forbidden from being
run. Tasks beginning with '_' are automatically denied, and we look
into the @forbidden_methods package variable for further
enlightenment. Return 1 if allowed, 0 if forbidden.

B<_check_task_security>

Called to ensure this $task can be run by the currently logged-in
user. Default behavior is to check the security for this user and
module against the package hash B<security>, which has tasks as keys
and security levels as values.

Note: you can define a default security for your methods and then
specify security for only the ones you need using the exported
constant 'DEFAULT_SECURITY_KEY'. For instance:

  %My::Handler::Action = (
     DEFAULT_SECURITY_KEY() => SEC_LEVEL_READ,
     edit                   => SEC_LEVEL_WRITE,
  );

So all methods except 'edit' are protected by SEC_LEVEL_READ.

Returns: the level for this user and this task.

B<_local_task>

This is an empty method in the GenericDispatcher, but you can create a
subclass of the dispatcher for your application to do application-wide
actions. For instance, if you had a tag in every handler that was to
be set in $R-E<gt>{page} and parsed by the main template to select a
particular 'tab' on your web page, you could do so in this method.

=head2 Caching

Note that the C<\%params> parameter for both of these methods should
be the same as the one passed to your implementation method. For
instance, in this snippet it would be the hashref C<$p>:

 sub listing {
     my ( $class, $p ) = @_;
 }

Yes, this is awkward. But the current version of OpenInteract content
handlers is stateless -- they use class methods rather than
objects. The next version will take care of this, but in the meantime
we need to pass around more parameters than normal.

Also note that users who are administrators -- as defined in
L<OpenInteract::Auth|OpenInteract::Auth> or a relevant subclass -- do
not view or save cached content. This is to prevent OpenInteract from
caching a view that includes admin-only links, such as 'Edit' or
'Remove' that normal users do not see.

B<generate_content( \%params, \%key_params, \%template_params,
                    \%template_variables, \%template_source )>

or

B<generate_content( \%params, \%key_params,
                    \%template_variables, \%template_source )>

This optionally replaces the typical last call within a handler:

 return $R->template->handler( \%template_params, \%template_variables,
                               \%template_source );

The purpose is to catch the content before it is passed on and save it
to the cache. You can then retrieve it from the cache using
C<check_cache()>.

For example, if you currently do something like:

 sub listing {
     my ( $class, $p ) = @_;
     my $R = OpenInteract::Request->instance;
     my $thingy_id = $R->apache->param( 'thingy_id' );
     my $thingy = $R->thingy->fetch( $thingy_id );
     ...
     return $R->template->handler( {},
                                   { thingy => $thingy,
                                     error_msg => $error_msg },
                                   { name => 'mypkg::mytmpl' } );
 }

 sub listing {
     my ( $class, $p ) = @_;
     my $R = OpenInteract::Request->instance;
     my $thingy_id = $R->apache->param( 'thingy_id' );
     my $thingy = $R->thingy->fetch( $thingy_id );
     ...
     return $class->generate_content( $p,
                                      { thingy_id => $thingy_id },
                                      { thingy => $thingy,
                                        error_msg => $error_msg, ... },
                                      { name => 'mypkg::mytmpl' } );
 }

There are three things happening here:

=over 4

=item *

We have jettisoned the first argument to C<template-E<gt>handler>,
since it was rarely used.

=item *

We have passed the hashref C<$p> as the first argument.

=item *

We have passed a hashref of parameters OI will use to cache the
content.

=back

B<check_cache( \%params, \%cache_params )>

If cached content exists that matches the cache key for your action
and the parameters you pass in, then it is returned.

 package My::Handler;

 use base qw( OpenInteract::Handler::GenericDispatcher );

 sub listing {
     my ( $class, $p ) = @_;
     my $R = OpenInteract::Request->instance;
     my $thingy_id = $R->apache->param( 'thingy_id' );
     my $cached = $class->check_cache( $p, { thingy_id => $thingy_id } );
     return $cached if ( $cached );
     ...
 }

B<clear_cache()>

Whenever you modify, add or remove an object, it is normally best to
clear the cache of all items your handler class has produced. All you
need to do is call:

  $class->clear_cache();

And everything that handler has created will be cleared out. When the
next call is made to one of the methods, it will first check the cache
for its content and, not finding it, generate it and set it in the
cache again.

=head2 Utility

B<_create_object( \%params )>

Create an object from the information passed in via GET/POST and
C<\%params>.

Parameters:

 _id_field: \@ or $ with field name(s) used to find ID value
 _class:    $ with class of object to create

Returns: object created with information, C<undef> if object ID not
found, C<die> thrown if object class or ID field not given, or if the
retrieval fails.

B<date_process( 'yyyy-mm-dd' )>

WARNING: This method might be removed altogether.

Return a hashref formatted:

 { year  => 'yyyy',
   month => 'mm',
   day   => 'dd' }

B<date_read( $prefix, [ \%defaults ] )>

Read in date information from GET/POST information. The fields are:

 day    => ${prefix}_day
 month  => ${prefix}_month
 year   => ${prefix}_year

If you want a default set for the day, month or year, pass the
information in a hashref as the second argument.

=head1 NOTES

B<Discussion about Creating a 'Real' Dispatcher>

Think about making available to a handler its configuration
information from the action.perl file, so you can set information
there and have it available in your environment without having to know
how your handler was called.

For instance, in your C<action.perl> you might have:

 {
    'news' => {
        language => 'en',
        class    => 'OpenInteract::Handler::News',
        security => 'no',
        title    => 'Weekly News',
        posted_on_format => "Posted: DATE_FORMAT( posted_on, '%M %e, %Y' )",
    },

    'nouvelles' => {
        language => 'fr',
        title    => 'Les Nouvelles',
        redir    => 'news',
        posted_on_format => "Les Post: DATE_FORMAT( posted_on, '%M %e, %Y' )",
    },

 }

A call to the URL '/nouvelles/' would make the information:

 {
   language => 'fr',
   title    => 'Les Nouvelles',
   security => 'no',
   class    => 'OpenInteract::Handler::News', 
   posted_on_format => "Les Post: DATE_FORMAT( posted_on, '%M %e, %Y' )",
 }

available to the handler via the $p variable passed in:

 my $info = $p->{handler_info};
 # $info->{language} is now 'fr'

Use this as the basis for a new class:
'OpenInteract::ActionDispatcher' which you use to call all
actions. The ActionDispatcher can lookup the action (and remember all
its properties, even through 'redir' calls like outlined above), can
check the executor of an action for whether the task can be executed
or not (whether the task exists, whether the task is allowed) and can
check the security of the task as well. At each step the
ActionDispatcher has the option of running its automated checks (which
it might cache by website...) or checking callbacks defined in the
content handler.

So each content handler would get two arguments: its own class and a
hashref of metadata, which would include:

 - task called ('task')

 - action info compiled ('action_info', a hashref with basic things
 like 'class', 'security', 'title' as well as any custom modifications
 by the developer

 - the security level for this user and this task ('security_level'
 and 'security' to be backward compatible)

We will use 'can' to see whether the callback exists in the handler
class so the callback could also be defined in a superclass of the
handler. So I could define a hierarchy of content handlers and have
things just work. (You can do this now, but it is a little more
difficult.)

One sticky thing: every request for an action would have to be
rewritten to use the dispatcher, although we could create a wrapper in
OpenInteract::Request to try for backward compatibility
('lookup_request' and all).

=head1 TO DO

B<Move utility methods to separate class>

=head1 BUGS

None known.

=head1 COPYRIGHT

Copyright (c) 2001-2002 intes.net, inc.. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters <chris@cwinters.com>
