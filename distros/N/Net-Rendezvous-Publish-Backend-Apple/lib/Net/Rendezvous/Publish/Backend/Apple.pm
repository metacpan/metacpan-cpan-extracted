use strict;
package Net::Rendezvous::Publish::Backend::Apple;
use XSLoader;
use base qw( Class::Accessor::Lvalue::Fast );
__PACKAGE__->mk_accessors(qw( _handles ));
our $VERSION = 0.02;

XSLoader::load __PACKAGE__;

sub new {
    my $self = shift;
    $self = $self->SUPER::new;
    $self->_handles = {};
    return $self;
}

sub _newhandle {
    my $self = shift;
    my $handle = shift;
    $self->_handles->{ $handle } = $handle;
    return $handle;
}

sub publish {
    my $self = shift;
    my %args = @_;
    return $self->_newhandle( xs_publish( map {
        $_ || ''
    } @args{ qw( object name type domain host port txt ) } ) );
}

sub publish_stop {
    my $self = shift;
    my $id = shift;
    xs_stop( $id );
    delete $self->_handles->{ $id };
}

sub step {
    my $self = shift;
    my $time = shift;
    $time *= 1000; # millisecs
    xs_step_for( $time, values %{ $self->_handles } );
}

1;

__END__

=head1 NAME

Net::Rendezvous::Publish::Backend::Apple - interface to Apple's mDNS routines

=head1 DESCRIPTION

This module interfaces to the Apple's Rendezvous implementation in
order to allow service publishing on OS X machines.

=head1 AUTHOR

Richard Clamp <richardc@unixbeard.net>

=head1 COPYRIGHT

Copyright 2004, Richard Clamp.  All Rights Reserved.

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

Net::Rendezvous::Publish - the module this module supports

L<ADC's documentation of the DNS Service Discovery
API|http://developer.apple.com/documentation/Networking/Conceptual/dns_discovery_api/index.html>
