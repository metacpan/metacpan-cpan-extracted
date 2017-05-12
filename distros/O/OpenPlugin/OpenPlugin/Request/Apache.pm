package OpenPlugin::Request::Apache;

# $Id: Apache.pm,v 1.5 2003/04/03 01:51:25 andreychek Exp $

use strict;
use OpenPlugin::Param();
use base   qw( OpenPlugin::Param );
use Apache::Request();


$OpenPlugin::Request::Apache::VERSION = sprintf("%d.%02d", q$Revision: 1.5 $ =~ /(\d+)\.(\d+)/);

sub init {
    my ( $self, $args ) = @_;

    # This is here for now because when compiling this module at Apache startup
    # time, we don't have an Apache::Request object yet.  We should find a
    # better way to do this though.
    return $self unless ( $args->{'apache'} );

    # Make sure we have an Apache::Request object
    unless ( $self->state->{'apache'} ) {

        # If passed in an Apache::Request object, use it
        if( ref $args->{'apache'} eq "Apache::Request" ) {
            $self->state->{'apache'} = $args->{'apache'};
        }
        # If passed in an Apache object, we can work with that too
        elsif( ref $args->{'apache'} eq "Apache" ) {
            $self->state->{'apache'} =
                Apache::Request->new( $args->{'apache'} );
        }
        else {
            $self->OP->exception->throw("When using the Apache driver, you ",
                    "must pass in an Apache or Apache::Request object!");
        }
    }

    # Set the uri
    $self->state->{'uri'} = $self->state->{'apache'}->uri;

    return $self;
}

sub object { my $self = shift; return $self->state->{apache}; }
sub uri    { my $self = shift; return $self->state->{uri};    }

1;

__END__

=pod

=head1 NAME

OpenPlugin::Request::Apache - Apache driver for the OpenPlugin::Param plugin

=head1 PARAMETERS

In order to use the Apache driver, you must pass in an Apache or
Apache::Request object when creating a new OpenPlugin object.  For example:

 my $r = shift;
 my $OP = OpenPlugin->new( request => { apache => $r } );

After the plugin is initialized, the Apache::Request object is accessible
to you using:

 $apache_req = $OP->request->object();

=head1 CONFIG OPTIONS

=over 4

=item * driver

Apache

=back

=head1 BUGS

None known.

=head1 TO DO

Nothing known.

=head1 SEE ALSO

L<OpenPlugin|OpenPlugin>
L<OpenPlugin::Param|OpenPlugin::Param>
L<Apache|Apache>
L<Apache::Request|Apache::Request>

=head1 COPYRIGHT

Copyright (c) 2001-2003 Eric Andreychek. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Eric Andreychek <eric@openthought.net>

=cut
