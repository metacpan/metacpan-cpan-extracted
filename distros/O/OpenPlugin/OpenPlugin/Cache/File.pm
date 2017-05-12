package OpenPlugin::Cache::File;

# $Id: File.pm,v 1.15 2003/04/03 01:51:24 andreychek Exp $

use strict;
use OpenPlugin::Cache();
use base           qw( OpenPlugin::Cache );
use Cache::FileCache();

$OpenPlugin::Cache::File::VERSION = sprintf("%d.%02d", q$Revision: 1.15 $ =~ /(\d+)\.(\d+)/);

sub init {
    my ( $self, $args ) = @_;

    $self->state( 'cache', Cache::FileCache->new() );

    return $self;
}

sub fetch {
    my ( $self, $id ) = @_;

    $self->OP->log->info( "Retrieving ($id) from the cache." );

    return $self->state->{cache}->get( $id );

}

sub save {
    my ( $self, $data, $params ) = @_;

    return undef unless $data;

    $params->{id} ||= OpenPlugin::Utility->generate_rand_id();

    $params->{expires} ||= OpenPlugin::Utility->expire_calc(
                                $self->OP->config->{plugin}{cache}{expires} );

    $self->state->{cache}->set( $params->{id},
                                $data,
                                $params->{expires}
                              );

    $self->OP->log->info( "Saved ($params->{id}) to the cache." );

    return $params->{id};

}

sub delete {
    my ( $self, $id ) = @_;

    $self->OP->log->info( "Deleting ($id) from the cache." );

    return $self->state->{cache}->remove( $id );

}


1;

__END__

=pod

=head1 NAME

OpenPlugin::Cache::File - File driver for the OpenPlugin::Cache plugin

=head1 PARAMETERS

None.

=head1 CONFIG OPTIONS

=over 4

=item * driver

File

=item * expires

You can set a detault expire time in the config file.  If an expiration is not
passed in with your data to cache, this default time from the config is used.

Example: +3h

=back

=head1 TO DO

None known.

=head1 BUGS

None known.

=head1 COPYRIGHT

Copyright (c) 2001-2003 Eric Andreychek. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Eric Andreychek <eric@openthought.net>

=cut
