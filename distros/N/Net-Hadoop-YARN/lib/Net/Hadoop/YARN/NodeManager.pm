package Net::Hadoop::YARN::NodeManager;
$Net::Hadoop::YARN::NodeManager::VERSION = '0.203';
use strict;
use warnings;
use 5.10.0;
use Moo;
use Data::Dumper;

with 'Net::Hadoop::YARN::Roles::Common';

has '+servers' => ( default => sub { ["localhost:50060"] }, );


sub info {
    my $self = shift;
    my $res = $self->_get("node/info");
    return $res->{nodeInfo} || $res;
}


sub app {
    my $self = shift;
    return $self->apps(@_);
}

sub apps {
    my $self = shift;
    my $app_id;
    my $options;
    if ( @_ == 1 ) {
        if ( !ref $_[0] ) {
            $app_id = shift;
        }
        else {
            $options = shift;
        }
    }
    elsif ( @_ > 1 ) {
        $options = {@_};
    }
    my $res = $self->_get(
        $app_id ? "node/apps/$app_id" : ( "node/apps", { params => $options } )
    );
    return $res->{app} || $res;
}


sub container {
    my $self = shift;
    return $self->containers(@_);
}

sub containers {
    my $self = shift;
    my $container_id = shift;
    my $res = $self->_get( "node/containers" . ($container_id ? "/$container_id" : "") );
    return $res->{container} || $res;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Hadoop::YARN::NodeManager

=head1 VERSION

version 0.203

=head1 METHODS

=head2 info

NodeManager Information API

=head2 apps

=head2 app

Applications API & Application API

parameters are either a hash(/ref) or an application ID

=head2 state

application state 

=head2 user

user name

=head2 containers

=head2 container

Containers API

pass a container ID to get information on a specific one, otherwise get the full list

=head1 AUTHOR

David Morel <david.morel@amakuru.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by David Morel & Booking.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
