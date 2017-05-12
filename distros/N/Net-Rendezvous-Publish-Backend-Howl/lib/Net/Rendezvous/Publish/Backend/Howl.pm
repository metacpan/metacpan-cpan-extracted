package Net::Rendezvous::Publish::Backend::Howl;
use strict;
use warnings;
use XSLoader;
use base qw( Class::Accessor::Lvalue::Fast );
__PACKAGE__->mk_accessors(qw( _handle _salt ));
our $VERSION = 0.03;

XSLoader::load __PACKAGE__;

sub new {
    my $self = shift;
    $self = $self->SUPER::new;
    $self->_handle = init_rendezvous();
    $self->_salt   = get_salt( $self->_handle );
    return $self;
}

sub DESTROY {
    my $self = shift;
    sw_rendezvous_fina( $self->_handle );
}

sub publish {
    my $self = shift;
    my %args = @_;
    $args{txt} = [ split /\x{1}/, $args{txt} ];
    return xs_publish( $self->_handle, map {
        $_ || ''
    } @args{qw( object name type domain host port txt )} );
}

sub publish_stop {
    my $self = shift;
    my $id   = shift;
    return sw_discovery_cancel( $self->_handle, $id );
}

sub step {
    my $self = shift;
    my $howlong = @_ ? shift : 0.5;
    $howlong *= 1000; # millisecs
    run_step( $self->_salt, $howlong );
}

1;
__END__

=head1 NAME

Net::Rendezvous::Publish::Backend::Howl - interface to Porchdog software's Howl library

=head1 DESCRIPTION

This module interfaces to the Porchdog's Howl library in order to
allow service publishing.

=head1 AUTHOR

Richard Clamp <richardc@unixbeard.net>

=head1 COPYRIGHT

Copyright 2004, Richard Clamp.  All Rights Reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

Net::Rendezvous::Publish - the module this module supports

L<Howl|http://www.porchdogsoft.com/products/howl/>

=cut
