package OpenPlugin::Param;

# $Id: Param.pm,v 1.16 2003/04/03 01:51:24 andreychek Exp $

use strict;
use base qw( OpenPlugin::Plugin );

$OpenPlugin::Param::VERSION = sprintf("%d.%02d", q$Revision: 1.16 $ =~ /(\d+)\.(\d+)/);

sub OP   { return $_[0]->{_m}{OP} }
sub type { return 'param' }

*get = \*get_incoming;

# Retrieve GET/POST parameters
sub get_incoming {
    my ( $self, $name ) = @_;

    # Just return a list of available parameters
    unless ( $name ) {
        return ( ref $self->state->{param} eq 'HASH' )
                 ? keys %{ $self->state->{param} } : ();
    }

    # This parameter has a list of values
    if ( ref $self->state->{param}{ $name } eq 'ARRAY' and wantarray ) {
        return @{ $self->state->{param}{ $name } };
    }

    # Return a single parameter
    return $self->state->{param}{ $name };
}


sub set_incoming {
    my ( $self, @args ) = @_;
    return undef unless ( $args[0] );

    if( ref $args[0] eq 'HASH' ) {
        foreach my $arg ( keys %{ $args[0] } ) {
            $self->state->{ param }{ $arg } = $args[0]->{ $arg };
        }
    }
    else {
        $self->state->{ param }{ $args[0] } = $args[1];
    }
}


1;

__END__

=pod

=head1 NAME

OpenPlugin::Param - Retrieve GET/POST/other values sent by client with a request

=head1 SYNOPSIS

 $OP = OpenPlugin->new();

 @params = $OP->param->get_incoming();

 $param  = $OP->param->get_incoming('param');

=head1 DESCRIPTION

The Param plugin offers an interface to retrieve parameters sent from the
browser to the server.

=head1 METHODS

B<get_incoming( [ $fieldname ] )>

B<get( [ $fieldname ] )>

Called with no parameters, C<get_incoming()> returns a list containing the
names of each parameter sent to the server.

Called with one parameter, get_incoming returns value(s) for C<$fieldname>.
Call in list context to return multiple values for C<$fieldname>.

B<set_incoming( $fieldname => $value )>

Set the value of an incoming parameter.  This is typically called internally
when the server receives parameters by the browser.  However, sometimes
developers find it useful to be able to modify this value, perhaps in order to
do sanity checking on the information sent from the user.

The C<$value> parameter can be a reference to a hash, if there are multiple
values for a particular field.

=head1 BUGS

None known.

=head1 TO DO

See the TO DO section of the <OpenPlugin::Request> plugin.

=head1 SEE ALSO

See the individual driver documentation for settings and parameters specific to
that driver.

=head1 COPYRIGHT

Copyright (c) 2001-2003 Eric Andreychek. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Eric Andreychek <eric@openthought.net>

=cut
