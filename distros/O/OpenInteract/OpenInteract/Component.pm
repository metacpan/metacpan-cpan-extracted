package OpenInteract::Component;

# $Id: Component.pm,v 2.16 2002/09/16 19:53:34 lachoy Exp $

use strict;
use SPOPS::Secure qw( :level );
use Data::Dumper  qw( Dumper );

$OpenInteract::Component::VERSION = sprintf("%d.%02d", q$Revision: 2.16 $ =~ /(\d+)\.(\d+)/);

use constant DEFAULT_METHOD    => 'handler';
use constant NOTFOUND_SECURITY => SEC_LEVEL_NONE;

sub handler {
    my ( $class, $p, $return_info ) = @_;
    my $R = OpenInteract::Request->instance;
    unless ( $p->{name} ) {
        $R->scrib( 0, "ERROR: cannot execute component without a name!",
                      "Information passed in:\n", Dumper( $p ) );
        return undef;
    }

    my @modified_action = $class->_modify_action( $p->{name}  );
    my $action_info = $R->lookup_action([ $p->{name}, @modified_action ],
                                        { return => 'info', skip_default => 1 });

    # If we don't find a action, assume that we're simply calling a
    # template with the specified name; note that if we pass in
    # 'template' (like for boxes) that are in the 'pkg::template'
    # format we set the 'package' key below

    unless ( scalar keys %{ $action_info } ) {
        $R->DEBUG && $R->scrib( 1, "No action info returned; just using template name." );
        $action_info->{name}       = $p->{name};
        $action_info->{template}   = $p->{template} || $action_info->{name};
        $action_info->{package}    = $p->{package};
        $R->DEBUG && $R->scrib( 1, "Using template ($action_info->{template})",
                                   "(package if needed: $action_info->{package})" );
    }

    unless ( $action_info->{template} or
             $action_info->{class} or
             ref $action_info->{code} ) {
        $R->DEBUG && $R->scrib( 1, "No relevant action info; using name ($p->{name}) as template" );
        $action_info->{template} = $p->{name};
    }
    $R->DEBUG && $R->scrib( 2, "Action_info:\n", Dumper( $action_info ) );

    # If the template is not in 'pkg::template' format, set it up so
    # Most of this confusing stuff is for backward compatibility; in a
    # few revs we'll take it out

    if ( $action_info->{template} ) {
        if ( $action_info->{template} =~ /^(\w+)::(\w+)$/ ) {
            $action_info->{template_name} = $action_info->{template};
            $action_info->{package}       = $1;
            $action_info->{template}      = $2;
        }
        else {
            $action_info->{template_name} = join( '::', $action_info->{package}, $action_info->{template} );
        }
    }

    $action_info->{package} ||= $action_info->{package_name};

    # If the component defines a key named 'params', use that
    # information as the data to feed the component. Otherwise just use
    # whatever was passed in.

    my $params = ( ref $p->{params} ) ? $p->{params} : $p;
    $R->DEBUG && $R->scrib( 3, "Parameters being passed to component:\n", Dumper( $params ) );

    # Now that we have information for the component, go ahead and
    # process it -- output goes to $html. Note that if no component
    # information is specified the 'template_name' key in $action_info
    # should have been specified. If no template is found then
    # OpenInteract::Template will give us an error message in $html

    my ( $html );

    # Process the standalone template

    if ( $action_info->{template_name} ) {
        $R->DEBUG && $R->scrib( 1, "Generic template action with ($action_info->{template_name})" );
        $html = eval { $R->template->handler( {}, $params,
                                              { name => $action_info->{template_name} } ) };
    }

    # Run the code reference 

    elsif ( ref $action_info->{code} eq 'CODE' ) {
        $html = eval { $action_info->{code}->( $params ) };
    }

    # Run the class->method call

    elsif ( my $action_class = $action_info->{class} ) {
        $action_info->{method} ||= DEFAULT_METHOD;
        $R->DEBUG && $R->scrib( 1, "Calling component with $action_class->$action_info->{method}" );

        # Check security unless explicitly told not to

        unless ( $action_info->{security} eq 'no' ) {
            my $target_level = SEC_LEVEL_NONE;
            ( $target_level, $params->{level} ) = $class->_check_security( $action_info );
            return undef unless ( $params->{level} >= $target_level );
        }
        my $method = $action_info->{method};
        $html = eval { $action_class->$method( $params ) };
    }
    $R->scrib( 0, "Died with error message: $@" )  if ( $@ );
    $R->DEBUG && $R->scrib( 2, "Component generated the following:\n$html" );

    # If they want the action information used by the component
    # (evidenced by requesting a list of information from the call) ,
    # send the content and the action info to the caller

    return ( $return_info ) ? ( $html, $action_info ) : $html;
}



sub _check_security {
    my ( $class, $action_info ) = @_;
    my $R = OpenInteract::Request->instance;
    no strict 'refs';
    my $required_level = SEC_LEVEL_WRITE;
    if ( my $verbose_level = $action_info->{security_required} ) {
        $required_level = SEC_LEVEL_WRITE  if ( $verbose_level eq 'WRITE' );
        $required_level = SEC_LEVEL_READ   if ( $verbose_level eq 'READ' );
        $required_level = SEC_LEVEL_NONE   if ( $verbose_level eq 'NONE' );
    }
    elsif ( $action_info->{class} ) {
        my %all_levels   = %{ $action_info->{class} . '::security' };
        $required_level = $all_levels{ $action_info->{method} } || NOTFOUND_SECURITY;
    }
    $R->DEBUG && $R->scrib( 1, "Checking security for component." );
    my $current_level   = eval { $R->secure->check_security({
                                          security_object_class => $R->security_object,
                                          db        => $R->db,
                                          user      => $R->{auth}->{user},
                                          class     => $action_info->{class},
                                          object_id => '0' }) };
    $current_level ||= SEC_LEVEL_WRITE;
    $R->DEBUG && $R->scrib( 1, "Target security: ($required_level); Actual: ($current_level)" );
    return ( $required_level, $current_level );
}



# Create additional names under which we might find the action in the
# action table

sub _modify_action {
    my ( $class, $action ) = @_;
    my @modified = ( lc $action );
    $action =~ s/[\_\-\s]//g;
    push @modified, $action;
    return @modified;
}

1;

__END__

=head1 NAME

OpenInteract::Component - Central calling/caching module for components

=head1 DESCRIPTION

A Component can be called from either a 'Static' page, from a
template, or from anything else in the system.  from another content
handler. A component is called the same either way:

 my $html = OpenInteract::Component->handler( $action, \%params )
 my $html = $R->component->handler( $action, \%params );

within a static page, you can normally simply do (using Template
Toolkit):

 [% OI.comp( 'action', param = 'value', param = 'value' ) %]

where C<$action> is a key for looking up the actual class of the
handler in the Action Table that will generate the HTML returned to
the original caller. (See
L<OpenInteract::Template::Plugin|OpenInteract::Template::Plugin> for
the C<comp> subroutine which translates the template call into the
necessary format for this handler.)

This class basically exists as a stub to setup/automate some items for
items that are simple and do not need a whole class behind them to
implement a reusable item.

=head1 TO DO

Nothing known

=head1 BUGS

None known

=head1 SEE ALSO

I<OpenInteract Component Guide> for more information on
components. (In C<doc/> subdirectory of main distribution.)

=head1 COPYRIGHT

Copyright (c) 2001-2002 intes.net, inc.. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters <chris@cwinters.com>
